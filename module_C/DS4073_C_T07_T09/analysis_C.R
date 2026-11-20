# DS4073 member C: gear type (T07–T09). Base R only.
# Run: Rscript analysis_C.R PATH_TO_DS4073_GFW_2023_Shared [OUTPUT_DIRECTORY]
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || length(args) > 2L) stop("Usage: Rscript analysis_C.R SHARED_DIR [OUTPUT_DIR]")
shared <- normalizePath(args[1], mustWork = TRUE)
out <- if (length(args) == 2L) args[2] else "results"
dir.create(file.path(out, "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(out, "tables"), recursive = TRUE, showWarnings = FALSE)
data_dir <- file.path(shared, "data")
read_csv <- function(path) read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
write_csv <- function(x, name) write.csv(x, file.path(out, "tables", name), row.names = FALSE, na = "")
check <- function(condition, message) if (!isTRUE(condition)) stop(message, call. = FALSE)
fmt <- function(x, digits = 1) formatC(x, format = "f", digits = digits, big.mark = ",")
display_gear <- function(x) ifelse(x == "fishing", "Unspecified fishing", gsub("_", " ", x))
annual <- read_csv(file.path(data_dir, "summary", "annual_gear.csv"))
monthly <- read_csv(file.path(data_dir, "summary", "monthly_gear.csv"))
global <- read_csv(file.path(data_dir, "summary", "monthly_global.csv"))
qa <- read_csv(file.path(shared, "qa", "monthly_checks.csv"))
check(all(c("geartype", "fishing_hours") %in% names(annual)), "Annual gear fields missing")
check(all(c("date", "geartype", "fishing_hours") %in% names(monthly)), "Monthly gear fields missing")
check(!anyNA(annual$fishing_hours) && all(annual$fishing_hours >= 0), "Bad annual values")
check(!anyDuplicated(annual$geartype), "Duplicate annual gear labels")
check(!anyDuplicated(paste(monthly$date, monthly$geartype)), "Duplicate month/gear rows")
check(identical(sort(unique(monthly$date)), sprintf("2023-%02d-01", 1:12)), "Expected all 12 months of 2023")
total <- sum(annual$fishing_hours)
check(abs(total - 111712128.6941) < 0.001, "Global total differs from A/shared package")
annual <- annual[order(-annual$fishing_hours, annual$geartype), ]
annual$rank <- seq_len(nrow(annual))
annual$label <- display_gear(annual$geartype)
annual$share <- annual$fishing_hours / total
annual <- annual[, c("rank", "geartype", "label", "hours", "fishing_hours", "share")]
write_csv(annual, "T07_annual_gear.csv")

# T08: fixed categories across all months. Keep the unclassified 'fishing' separate.
# All remaining original categories are mapped one-to-one into Other.
featured <- head(annual$geartype[annual$geartype != "fishing"], 5)
category <- function(x) ifelse(x == "fishing", "Unspecified fishing",
                                ifelse(x %in% featured, display_gear(x), "Other classified gear"))
monthly$category <- category(monthly$geartype)
monthly_group <- aggregate(monthly$fishing_hours,
                           list(date = monthly$date, category = monthly$category), sum)
names(monthly_group)[3] <- "fishing_hours"
month_total <- aggregate(monthly$fishing_hours, list(date = monthly$date), sum)
names(month_total)[2] <- "month_hours"
month_total <- merge(month_total, global[, c("date", "fishing_hours")], by = "date")
names(month_total)[3] <- "global_hours"
qa$month <- paste0(qa$month, "-01")
month_total <- merge(month_total, qa[, c("month", "clean_fishing_hours")],
                     by.x = "date", by.y = "month", all.x = TRUE)
check(nrow(month_total) == 12L && !anyNA(month_total), "Monthly QA records missing")
check(all(abs(month_total$month_hours - month_total$global_hours) < 0.001), "T08 does not reconcile to monthly global")
check(all(abs(month_total$month_hours - month_total$clean_fishing_hours) < 0.001), "T08 does not reconcile to cleaned detail")
check(abs(sum(month_total$month_hours) - total) < 0.001, "Monthly totals do not reconcile to annual")
monthly_group <- merge(monthly_group, month_total[, c("date", "month_hours")], by = "date")
monthly_group$share <- monthly_group$fishing_hours / monthly_group$month_hours
check(all(abs(aggregate(monthly_group$share, list(monthly_group$date), sum)$x - 1) < 1e-10), "Monthly shares do not sum to 100%")
write_csv(monthly_group[order(monthly_group$date, monthly_group$category), ], "T08_monthly_gear_share.csv")

# T09 selects the three highest ranked specifically named gears from T07.
# The second ranked label 'fishing' is not a gear type; it is shown in T07/T08.
selected <- head(annual$geartype[annual$geartype != "fishing"], 3)
map_parts <- vector("list", 12)
detail_checks <- vector("list", 12)
for (m in 1:12) {
  date <- sprintf("2023-%02d-01", m)
  detail <- readRDS(file.path(data_dir, "detail", sprintf("2023-%02d.rds", m)))
  check(all(c("geartype", "cell_ll_lon", "cell_ll_lat", "fishing_hours") %in% names(detail)), paste("Detail fields missing", date))
  detail_checks[[m]] <- data.frame(date = date, detail_hours = sum(detail$fishing_hours),
                                   summary_hours = month_total$month_hours[month_total$date == date])
  check(abs(detail_checks[[m]]$detail_hours - detail_checks[[m]]$summary_hours) < 0.001,
        paste("Detail total differs from monthly summary", date))
  sub <- detail[detail$geartype %in% selected & detail$fishing_hours > 0,
                c("geartype", "cell_ll_lon", "cell_ll_lat", "fishing_hours")]
  # One-degree cells keep the worldwide small multiples legible. The same
  # floor coordinate rule is used for every gear; zero/no-row stay blank.
  sub$lon <- floor(sub$cell_ll_lon)
  sub$lat <- floor(sub$cell_ll_lat)
  map_parts[[m]] <- aggregate(sub$fishing_hours,
                              list(geartype = sub$geartype, lon = sub$lon, lat = sub$lat), sum)
  names(map_parts[[m]])[4] <- "fishing_hours"
  rm(detail, sub)
  gc(verbose = FALSE)
}
detail_checks <- do.call(rbind, detail_checks)
write_csv(detail_checks, "C_detail_reconciliation.csv")
map_monthly <- do.call(rbind, map_parts)
map <- aggregate(map_monthly$fishing_hours,
                 list(geartype = map_monthly$geartype, lon = map_monthly$lon, lat = map_monthly$lat), sum)
names(map)[4] <- "fishing_hours"
map$label <- display_gear(map$geartype)
map <- map[order(match(map$geartype, selected), map$lat, map$lon), ]
write_csv(map, "T09_gear_map_1deg.csv")
map_check <- aggregate(map$fishing_hours, list(geartype = map$geartype), sum)
names(map_check)[2] <- "map_hours"
map_check <- merge(map_check, annual[, c("geartype", "fishing_hours")], by = "geartype")
check(all(abs(map_check$map_hours - map_check$fishing_hours) < 0.001), "T09 maps do not reconcile to T07")
write_csv(map_check, "T09_map_reconciliation.csv")

# Figures: simple, readable base-R output with one unit and one color range.
png(file.path(out, "figures", "T07_gear_ranking.png"), width = 2400, height = 1700, res = 210)
par(mar = c(6.8, 11.4, 5, 5), bg = "white", family = "sans")
vals <- rev(annual$fishing_hours / 1e6)
labs <- rev(annual$label)
cols <- ifelse(rev(annual$geartype) == "fishing", "#A0AAB1", "#247C83")
bp <- barplot(vals, names.arg = labs, horiz = TRUE, las = 1, col = cols, border = NA,
              xlim = c(0, max(vals) * 1.15), cex.names = 0.82,
              main = "T07  Fishing hours by gear classification", xlab = "Estimated fishing hours (millions)")
text(vals + max(vals) * 0.008, bp, sprintf("%.2f", vals), pos = 4, cex = 0.66)
mtext("Global Fishing Watch v3.0, 2023  |  'fishing' = gear not specified  |  Total: 111.71 million hours",
      side = 1, line = 5.4, cex = 0.63, col = "#475964")
dev.off()

cats <- c(display_gear(featured), "Unspecified fishing", "Other classified gear")
mat <- matrix(0, nrow = length(cats), ncol = 12, dimnames = list(cats, sprintf("%02d", 1:12)))
for (i in seq_len(nrow(monthly_group))) {
  m <- as.integer(substr(monthly_group$date[i], 6, 7))
  mat[monthly_group$category[i], m] <- monthly_group$share[i]
}
check(all(abs(colSums(mat) - 1) < 1e-10), "Stacked bars are incomplete")
palette <- c("#167C80", "#4B5B9B", "#C48643", "#85A64D", "#A96180", "#929CA5", "#D4C8B4")
png(file.path(out, "figures", "T08_monthly_gear_mix.png"), width = 2300, height = 1450, res = 210)
layout(matrix(c(1, 2), 2, 1), heights = c(4.8, 1))
par(mar = c(4, 5, 4, 1), bg = "white", family = "sans")
barplot(mat * 100, col = palette, border = NA, ylim = c(0, 100),
        names.arg = month.abb, ylab = "Share of that month's estimated fishing hours (%)",
        main = "T08  Gear composition by month (2023)")
abline(h = seq(0, 100, 20), col = "#DDE5E8", lty = 3)
par(mar = c(0, 1, 0, 1)); plot.new()
legend("center", legend = cats, fill = palette, bty = "n", cex = 0.85, ncol = 4)
text(0.5, 0.12, "Fixed categories across 12 months  |  Unspecified gear shown separately  |  Each month totals 100%",
     cex = 0.72, col = "#475964")
dev.off()

breaks <- c(0, 1, 10, 100, 1000, 10000, 100000, Inf)
fill <- c("#C8D6DA", "#D9EEE9", "#A7D8CA", "#70B9AF", "#32979A", "#176B83", "#273E74")
png(file.path(out, "figures", "T09_gear_maps.png"), width = 2550, height = 1750, res = 180)
layout(matrix(c(1, 2, 3, 4), 4, 1), heights = c(1, 1, 1, 0.24))
par(mar = c(3.1, 5.2, 3.5, 2.2), oma = c(0, 0, 3.2, 0), bg = "white", family = "sans")
for (gear in selected) {
  d <- map[map$geartype == gear, ]
  z <- matrix(NA_real_, nrow = 360, ncol = 180)
  z[cbind(d$lon + 181L, d$lat + 91L)] <- d$fishing_hours
  bins <- matrix(findInterval(z, breaks, rightmost.closed = TRUE), nrow = 360)
  bins[is.na(z)] <- NA
  image(x = seq(-179.5, 179.5), y = seq(-89.5, 89.5), z = bins,
        col = fill, breaks = seq(0.5, 7.5, 1), xlab = "", ylab = "Latitude",
        axes = FALSE, main = sprintf("%s  |  %.2f million hours", display_gear(gear),
                                    annual$fishing_hours[annual$geartype == gear] / 1e6),
        useRaster = TRUE)
  axis(1, at = seq(-180, 180, 60)); axis(2, at = seq(-90, 90, 30), las = 1)
  abline(v = seq(-180, 180, 60), h = seq(-90, 90, 30), col = "#CCD7DA", lty = 3)
  box(col = "#9DADB3")
}
mtext("T09  Where the three highest-hour named gears are observed", side = 3, outer = TRUE, line = 1.3, cex = 1.4, font = 2)
par(mar = c(0, 1, 0, 1)); plot.new()
legend("top", horiz = TRUE, legend = c("0-1", "1-10", "10-100", "100-1k", "1k-10k", "10k-100k", "100k+"),
       fill = fill, bty = "n", cex = 0.82, title = "Hours per 1-degree cell")
text(0.5, 0.08, "All panels use the same 1-degree grid and color range; blank = no positive recorded hours.", cex = 0.78)
dev.off()

summary <- data.frame(metric = c("global_hours", "gear_categories", "months", "unspecified_gear_hours",
                                 "unspecified_gear_share", "selected_named_gears", "map_grid_degrees"),
                      value = c(sprintf("%.4f", total), nrow(annual), 12,
                                sprintf("%.4f", annual$fishing_hours[annual$geartype == "fishing"]),
                                sprintf("%.8f", annual$share[annual$geartype == "fishing"]),
                                paste(selected, collapse = ";"), 1))
write_csv(summary, "C_summary.csv")
cat("Completed T07–T09. Total hours:", fmt(total, 4), "\n")
cat("Top named gears:", paste(selected, collapse = ", "), "\n")
cat("Output:", normalizePath(out), "\n")
