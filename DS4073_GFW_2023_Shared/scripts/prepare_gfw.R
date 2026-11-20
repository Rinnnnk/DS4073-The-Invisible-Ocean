# Usage: Rscript scripts/prepare_gfw.R INPUT_ZIP FAO_GEOJSON EMPTY_OUTPUT_DIR
# Builds the shared data using Global Fishing Watch v3.0 and FAO Major Fishing Areas.
suppressPackageStartupMessages(library(data.table))
library(sf)
setDTthreads(min(4L, getDTthreads()))

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop("Usage: Rscript scripts/prepare_gfw.R INPUT_ZIP FAO_GEOJSON EMPTY_OUTPUT_DIR")
}
archive <- normalizePath(args[1], mustWork = TRUE)
boundary_file <- normalizePath(args[2], mustWork = TRUE)
output <- args[3]
expected_md5 <- "c7ddb54e8cf0b89aa30a9fea588e6253"
stopifnot(unname(tools::md5sum(archive)) == expected_md5)
if (dir.exists(output) && length(list.files(output, all.files = TRUE, no.. = TRUE))) {
  stop("Choose a fresh output directory.")
}

months <- 1:12
month_start <- sprintf("2023-%02d-01", months)
files <- paste0("fleet-monthly-csvs-10-v3-", month_start, ".csv")
members <- unzip(archive, list = TRUE)$Name
stopifnot(identical(sort(members[grepl("[.]csv$", members)]), files))

scratch <- tempfile("fishing_raw_")
dir.create(scratch)
unzip(archive, files = files, exdir = scratch)
dir.create(file.path(output, "data", "detail"), recursive = TRUE)
dir.create(file.path(output, "data", "monthly_grid"), recursive = TRUE)
dir.create(file.path(output, "data", "summary"), recursive = TRUE)
dir.create(file.path(output, "qa"), recursive = TRUE)

read_month <- function(index) {
  fields <- c("date", "year", "month", "cell_ll_lat", "cell_ll_lon", "flag",
              "geartype", "hours", "fishing_hours", "mmsi_present")
  dt <- fread(
    file.path(scratch, files[index]),
    colClasses = list(character = c("date", "flag", "geartype"),
                      integer = c("year", "month", "mmsi_present"),
                      numeric = c("cell_ll_lat", "cell_ll_lon", "hours", "fishing_hours"))
  )
  stopifnot(setequal(names(dt), fields), nrow(dt) > 0L, !anyNA(dt))
  stopifnot(all(dt$date == month_start[index]), all(dt$year == 2023L),
            all(dt$month == index), all(nzchar(dt$flag)), all(nzchar(dt$geartype)))
  for (field in c("hours", "fishing_hours", "mmsi_present")) {
    stopifnot(all(is.finite(dt[[field]])), all(dt[[field]] >= 0))
  }
  stopifnot(is.integer(dt$mmsi_present), all(dt$fishing_hours <= dt$hours + 1e-8))
  dt[, date := as.IDate(date)]
  lat10 <- round(dt$cell_ll_lat * 10)
  lon10 <- round(dt$cell_ll_lon * 10)
  stopifnot(all(abs(lat10 - dt$cell_ll_lat * 10) < 1e-8),
            all(abs(lon10 - dt$cell_ll_lon * 10) < 1e-8),
            all(lat10 >= -900 & lat10 < 900), all(lon10 >= -1800 & lon10 < 1800))
  dt[, grid_id := as.integer((lat10 + 900L) * 3600L + lon10 + 1801L)]
  stopifnot(!anyDuplicated(dt, by = c("date", "grid_id", "flag", "geartype")))
  dt[]
}

grid_centres <- function(ids) {
  data.table(grid_id = ids,
             lat_center = ((ids - 1L) %/% 3600L - 900L) / 10 + 0.05,
             lon_center = ((ids - 1L) %% 3600L - 1800L) / 10 + 0.05)
}

# FAO geometries are supplied in lon/lat and split at the antimeridian.
# Use planar point-in-polygon in those coordinates to retain parallels and meridians.
# Multiple geometry parts from the same area count as one area.
polygons <- st_read(boundary_file, quiet = TRUE)
stopifnot(st_crs(polygons)$epsg == 4326L, all(polygons$F_LEVEL == "MAJOR"),
          all(nchar(polygons$F_CODE) == 2L))
codes <- sort(unique(polygons$F_CODE))
stopifnot(identical(codes, c("18","21","27","31","34","37","41","47","48","51",
                             "57","58","61","67","71","77","81","87","88")))
st_geometry(polygons) <- st_make_valid(st_set_crs(st_geometry(polygons), NA))
area_names <- unique(as.data.table(st_drop_geometry(polygons))[, .(
  area_code = F_CODE, area_name = NAME_EN
)])
stopifnot(!anyDuplicated(area_names$area_code))
area_names <- rbind(area_names, data.table(
  area_code = c("UNMATCHED", "AMBIGUOUS"),
  area_name = c("Outside FAO marine polygons", "Multiple FAO marine areas")
))
setorder(area_names, area_code)

assign_areas <- function(ids) {
  centres <- grid_centres(ids)
  chunks <- split(seq_along(ids), (seq_along(ids) - 1L) %/% 80000L)
  for (rows in chunks) {
    points <- st_as_sf(as.data.frame(centres[rows]),
                       coords = c("lon_center", "lat_center"))
    matches <- st_intersects(points, st_geometry(polygons), prepared = TRUE)
    centres[rows, area_code := vapply(matches, function(indices) {
      if (!length(indices)) return("UNMATCHED")
      matches_for_grid <- unique(polygons$F_CODE[indices])
      if (length(matches_for_grid) > 1L) return("AMBIGUOUS")
      matches_for_grid
    }, character(1))]
  }
  centres[]
}

# Each grid is matched only once across the 12 monthly partitions.
lookup <- rep(NA_character_, 1800L * 3600L)
monthly_audits <- vector("list", 12)
monthly_sets <- vector("list", 12)
grid_totals <- vector("list", 12)
area_grid_qa <- vector("list", 12)
expected_total <- 111712128.6941
expected_rows <- 14560171L

# Amounts remain in hours. Never aggregate mmsi_present across cells or months.
summarise_hours <- function(dt, keys) {
  dt[, .(hours = sum(hours), fishing_hours = sum(fishing_hours)), by = keys]
}
assert_total <- function(actual, expected) stopifnot(abs(actual - expected) < 1e-4)

for (index in months) {
  dt <- read_month(index)
  before_rows <- nrow(dt)
  before_fishing <- sum(dt$fishing_hours)
  before_presence <- sum(dt$hours)
  grids <- sort(unique(dt$grid_id))
  new_grids <- grids[is.na(lookup[grids])]
  if (length(new_grids)) {
    message("Assigning ", length(new_grids), " new grids for ", month_start[index])
    assigned <- assign_areas(new_grids)
    lookup[assigned$grid_id] <- assigned$area_code
  }
  dt[, area_code := lookup[grid_id]]
  dt[, flag_group := flag]
  dt[grepl("^UNKNOWN($|-)", flag), flag_group := "UNKNOWN"]
  dt[flag == "UNK", flag_group := "UNK_UNRESOLVED"]
  stopifnot(!anyNA(dt), nrow(dt) == before_rows)
  assert_total(sum(dt$fishing_hours), before_fishing)
  assert_total(sum(dt$hours), before_presence)
  tag <- substr(month_start[index], 1, 7)
  saveRDS(dt, file.path(output, "data", "detail", paste0(tag, ".rds")))

  by_grid <- summarise_hours(dt, "grid_id")
  setorder(by_grid, grid_id)
  assert_total(sum(by_grid$fishing_hours), before_fishing)
  assert_total(sum(by_grid$hours), before_presence)
  grid_totals[[index]] <- by_grid
  saveRDS(by_grid, file.path(output, "data", "monthly_grid", paste0(tag, ".rds")))
  area_grid_qa[[index]] <- dt[, .(rows = .N, fishing_hours = sum(fishing_hours)),
                             by = area_code][, month := index]
  monthly_sets[[index]] <- summarise_hours(dt, c("date", "area_code", "geartype", "flag_group"))
  monthly_audits[[index]] <- data.table(
    month = tag, raw_rows = before_rows, clean_rows = nrow(dt), grids = length(grids),
    zero_fishing_rows = sum(dt$fishing_hours == 0),
    unknown_flag_rows = sum(dt$flag_group == "UNKNOWN"),
    unresolved_flag_rows = sum(dt$flag_group == "UNK_UNRESOLVED"),
    raw_hours = before_presence, clean_hours = sum(dt$hours),
    raw_fishing_hours = before_fishing, clean_fishing_hours = sum(dt$fishing_hours)
  )
  message("Completed ", tag, " with ", before_rows, " observations")
}

audit <- rbindlist(monthly_audits)
stopifnot(sum(audit$clean_rows) == expected_rows)
assert_total(sum(audit$clean_fishing_hours), expected_total)
fwrite(audit, file.path(output, "qa", "monthly_checks.csv"))
fwrite(rbindlist(area_grid_qa), file.path(output, "qa", "area_by_month_checks.csv"))

grid_lookup <- grid_centres(which(!is.na(lookup)))
grid_lookup[, area_code := lookup[grid_id]]
saveRDS(grid_lookup, file.path(output, "data", "grid_lookup.rds"))
fwrite(area_names, file.path(output, "data", "area_names.csv"))

summary_dir <- file.path(output, "data", "summary")
annual_grid <- summarise_hours(rbindlist(grid_totals), "grid_id")
setorder(annual_grid, grid_id)
stopifnot(identical(annual_grid$grid_id, grid_lookup$grid_id))
assert_total(sum(annual_grid$fishing_hours), expected_total)
assert_total(sum(annual_grid$hours), sum(audit$raw_hours))
saveRDS(annual_grid, file.path(summary_dir, "annual_grid.rds"))

area_summary <- annual_grid[, .(area_code = lookup[grid_id], fishing_hours)]
area_summary <- area_summary[, .(grids = .N, active_grids = sum(fishing_hours > 0),
                                fishing_hours = sum(fishing_hours)), by = area_code]
area_summary <- merge(area_summary, area_names, by = "area_code", all.x = TRUE)
fwrite(area_summary, file.path(output, "qa", "area_coverage.csv"))

# All compact summaries are built from the same monthly / area / gear / flag cube.
cube <- rbindlist(monthly_sets)
saveRDS(cube, file.path(summary_dir, "monthly_area_gear_flag.rds"))
summary_keys <- list(
  monthly_global = "date",
  monthly_area = c("date", "area_code"),
  annual_area = "area_code",
  monthly_gear = c("date", "geartype"),
  annual_gear = "geartype",
  annual_flag = "flag_group",
  annual_flag_area = c("flag_group", "area_code")
)
for (name in names(summary_keys)) {
  keys <- summary_keys[[name]]
  table <- summarise_hours(cube, keys)
  assert_total(sum(table$fishing_hours), expected_total)
  assert_total(sum(table$hours), sum(audit$raw_hours))
  setorderv(table, keys)
  fwrite(table, file.path(summary_dir, paste0(name, ".csv")))
}
writeLines(capture.output(sessionInfo()), file.path(output, "qa", "R_session_info.txt"))
message("Validated ", sum(audit$clean_rows), " rows and ", sum(audit$clean_fishing_hours),
        " fishing hours across ", nrow(grid_lookup), " grids")
