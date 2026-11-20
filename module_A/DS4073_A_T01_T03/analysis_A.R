# A page: T01 annual grid map, T02 FAO area comparison, T03 concentration.
# Run: Rscript analysis_A.R PATH_TO_EXTRACTED_SHARED_PACKAGE [OUTPUT_DIRECTORY]
library(data.table)
library(ggplot2)

hours_format <- function(x, digits = 0L) formatC(x, format = "f", digits = digits, big.mark = ",")
percent_format <- function(x) sprintf("%.2f%%", 100 * x)
source_line <- "Source: Global Fishing Watch v3.0, 2023"

a_theme <- function() {
  theme_minimal(base_size = 13) +
    theme(
      plot.background = element_rect(fill = "#FFFFFF", colour = NA),
      plot.title = element_text(colour = "#172F40", face = "bold", size = 20),
      plot.subtitle = element_text(colour = "#425D6D", size = 11, margin = margin(b = 14)),
      plot.caption = element_text(colour = "#506978", hjust = 0, size = 9, margin = margin(t = 10)),
      axis.title = element_text(colour = "#25475A"),
      axis.text = element_text(colour = "#25475A", size = 10),
      panel.grid.minor = element_blank(),
      plot.margin = margin(16, 20, 14, 18)
    )
}

read_a_data <- function(shared_dir) {
  data_dir <- file.path(shared_dir, "data")
  grid_hours <- readRDS(file.path(data_dir, "summary", "annual_grid.rds"))
  lookup <- readRDS(file.path(data_dir, "grid_lookup.rds"))
  area_hours <- fread(file.path(data_dir, "summary", "annual_area.csv"),
                      colClasses = c(area_code = "character"))
  area_names <- fread(file.path(data_dir, "area_names.csv"), colClasses = "character")

  stopifnot(!anyDuplicated(grid_hours$grid_id), !anyDuplicated(lookup$grid_id),
            !anyDuplicated(area_names$area_code), !anyDuplicated(area_hours$area_code),
            nrow(grid_hours) == nrow(lookup))
  grids <- lookup[grid_hours, on = "grid_id"]
  areas <- area_names[area_hours, on = "area_code"]
  total_hours <- sum(grids$fishing_hours)
  stopifnot(!anyNA(grids), !anyNA(areas), all(grids$fishing_hours >= 0), total_hours > 0,
            abs(total_hours - sum(areas$fishing_hours)) < 1e-4,
            abs(total_hours - 111712128.6941) < 1e-4)
  check <- grids[, .(grid_sum = sum(fishing_hours)), by = area_code]
  check <- check[areas, on = "area_code"]
  stopifnot(!anyNA(check$grid_sum), nrow(check) == uniqueN(grids$area_code),
            all(abs(check$grid_sum - check$fishing_hours) < 1e-4))
  list(grids = grids, areas = areas, total_hours = total_hours)
}

plot_annual_grid <- function(grids, land, peak) {
  # Tiles use the native 0.1-degree grid. WGS84 degrees stay on the plot axes.
  fill_ticks <- c(0, 1, 10, 100, 1000, 10000, 100000)
  geometry <- sf::st_cast(sf::st_geometry(land), "MULTIPOLYGON")
  land_xy <- as.data.table(sf::st_coordinates(geometry))
  land_xy[, polygon := paste(L3, L2, sep = "_")]
  ggplot() +
    geom_polygon(data = land_xy, aes(X, Y, group = polygon, subgroup = L1),
                 fill = "#E7E5DE", colour = "#A7B1B2", linewidth = 0.17) +
    geom_raster(data = grids, aes(lon_center, lat_center, fill = fishing_hours)) +
    geom_point(data = peak, aes(lon_center, lat_center), shape = 21,
               colour = "#151916", fill = NA, size = 3.1, stroke = 0.65) +
    coord_fixed(xlim = c(-180, 180), ylim = c(-90, 90), expand = FALSE) +
    scale_x_continuous(breaks = seq(-180, 180, 60)) +
    scale_y_continuous(breaks = seq(-90, 90, 30)) +
    scale_fill_gradientn(
      colours = c("#A8B4B9", "#D3F2E6", "#7ED5BF", "#35A98D", "#166C78", "#283B65", "#63264D"),
      values = scales::rescale(log1p(c(0, 1, 10, 100, 1000, 10000, max(grids$fishing_hours)))),
      transform = "log1p", breaks = fill_ticks, labels = scales::label_comma(),
      name = "Hours / grid (log1p)",
      guide = guide_colourbar(title.position = "left", barwidth = grid::unit(10, "cm"))
    ) +
    labs(
      title = "Where fishing activity was observed",
      subtitle = "Estimated annual fishing hours in each 0.1 degree grid cell, 2023",
      x = NULL, y = NULL,
      caption = paste(source_line, "| Land: Natural Earth.",
                      "\nGray tiles: recorded grids with zero fishing hours. Blank ocean: no row.",
                      "Outlined circle: highest-hour grid.")
    ) +
    a_theme() +
    theme(panel.background = element_rect(fill = "#FFFFFF", colour = NA),
          panel.grid.major = element_line(colour = "#E7EDF0", linewidth = 0.25),
          legend.position = "bottom", legend.justification = "left",
          legend.title = element_text(colour = "#25475A", size = 9),
          legend.text = element_text(colour = "#25475A", size = 9))
}

plot_areas <- function(areas) {
  areas <- copy(areas)
  areas[, label := fifelse(official_area, paste(area_code, area_name), "Unmatched grid centres")]
  areas[, label := factor(label, levels = rev(label))]
  ggplot(areas, aes(x = fishing_hours / 1e6, y = label)) +
    geom_col(aes(fill = category), width = 0.72) +
    geom_text(aes(label = hours_format(fishing_hours / 1e6, 3)),
              hjust = -0.12, colour = "#293F4D", size = 3) +
    scale_fill_manual(values = c("FAO area" = "#277D80", "Unmatched" = "#8999A2"), guide = "none") +
    scale_x_continuous(breaks = seq(0, 70, 10), expand = expansion(mult = c(0, 0.11))) +
    labs(title = "Fishing hours by FAO marine area",
         subtitle = "19 ranked marine areas, with unmatched grid centres shown separately",
         x = "Estimated fishing hours (millions)", y = NULL,
         caption = paste(source_line, "| FAO areas assigned by grid centre.")) +
    a_theme() +
    theme(panel.grid.major.y = element_blank(),
          panel.grid.major.x = element_line(colour = "#E4ECEF", linewidth = 0.4))
}

plot_concentration <- function(curve, cutoffs) {
  ggplot(curve, aes(grid_fraction, hours_fraction)) +
    geom_area(fill = "#D8EDE7") +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed", colour = "#8B9DA6") +
    geom_line(linewidth = 1.1, colour = "#167970") +
    geom_point(data = cutoffs, colour = "#9E4F26", size = 2.7) +
    scale_x_continuous(labels = scales::label_percent(), breaks = seq(0, 1, 0.2),
                       expand = expansion(mult = c(0, 0.015))) +
    scale_y_continuous(labels = scales::label_percent(), breaks = seq(0, 1, 0.2),
                       expand = expansion(mult = c(0, 0.025))) +
    labs(title = "How concentrated were fishing hours?",
         subtitle = sprintf("Top 1%% of active grids: %s   /   Top 5%%: %s   /   Top 10%%: %s",
                            percent_format(cutoffs$hours_fraction[1]),
                            percent_format(cutoffs$hours_fraction[2]),
                            percent_format(cutoffs$hours_fraction[3])),
         x = "Cumulative share of active grids, ranked from highest hours",
         y = "Cumulative share of fishing hours",
         caption = paste(source_line, "| Dashed line: equal hours per active grid.")) +
    a_theme() +
    theme(panel.grid.major = element_line(colour = "#E2ECEF", linewidth = 0.4))
}

run_a <- function(shared_dir, output_dir = "results", land_zip = "assets/ne_110m_land.zip") {
  input <- read_a_data(shared_dir)
  grids <- input$grids
  areas <- input$areas
  total <- input$total_hours
  areas[, official_area := grepl("^[0-9]{2}$", area_code)]
  stopifnot(sum(areas$official_area) == 19L,
            all(areas[official_area == FALSE, area_code] == "UNMATCHED"))
  areas[, category := fifelse(official_area, "FAO area", "Unmatched")]
  setorder(areas, -official_area, -fishing_hours, area_code)
  areas[, share_of_global := fishing_hours / total]

  ranked <- grids[fishing_hours > 0, .(grid_id, fishing_hours)]
  setorder(ranked, -fishing_hours, grid_id)
  n <- nrow(ranked)
  stopifnot(abs(sum(ranked$fishing_hours) - total) < 1e-4)
  cumulative <- c(0, cumsum(ranked$fishing_hours))
  stopifnot(abs(tail(cumulative, 1L) - total) < 1e-4)
  fractions <- c(0.01, 0.05, 0.10)
  top_n <- ceiling(fractions * n)
  cutoffs <- data.table(top_grid_percent = fractions * 100, grids = top_n,
                        grid_fraction = top_n / n, fishing_hours = cumulative[top_n + 1L])
  cutoffs[, hours_fraction := fishing_hours / total]
  draw_ranks <- sort(unique(c(0, round(seq(0, n, length.out = 1801)), top_n)))
  curve <- data.table(rank = draw_ranks, grid_fraction = draw_ranks / n,
                      hours_fraction = cumulative[draw_ranks + 1L] / total)
  stopifnot(abs(tail(curve$hours_fraction, 1L) - 1) < 1e-12)

  peak <- grids[ranked[1L, .(grid_id)], on = "grid_id"]
  top_grids <- grids[ranked[1:10, .(grid_id)], on = "grid_id"]
  shp_dir <- tempfile("ne_land_")
  dir.create(shp_dir)
  files <- unzip(land_zip, list = TRUE)$Name
  unzip(land_zip, files = files[grepl("[.](shp|shx|dbf|prj)$", files)], exdir = shp_dir)
  land <- sf::st_read(file.path(shp_dir, "ne_110m_land.shp"), quiet = TRUE)

  figures <- file.path(output_dir, "figures")
  tables <- file.path(output_dir, "tables")
  dir.create(figures, showWarnings = FALSE, recursive = TRUE)
  dir.create(tables, showWarnings = FALSE, recursive = TRUE)
  save_plot <- function(name, plot, width, height) {
    path <- file.path(figures, paste0(name, ".png"))
    ggsave(path, plot, width = width, height = height, dpi = 210, bg = "white")
    path
  }
  paths <- c(
    T01 = save_plot("T01_annual_grid_map", plot_annual_grid(grids, land, peak), 12, 7.35),
    T02 = save_plot("T02_fao_area_ranking", plot_areas(areas), 10.4, 8.4),
    T03 = save_plot("T03_grid_concentration", plot_concentration(curve, cutoffs), 10.4, 6.35)
  )
  fwrite(top_grids, file.path(tables, "T01_top_grids.csv"))
  fwrite(areas[, .(area_code, area_name, official_area, hours, fishing_hours, share_of_global)],
         file.path(tables, "T02_fao_area_totals.csv"))
  fwrite(cutoffs, file.path(tables, "T03_top_grid_shares.csv"))
  fwrite(curve, file.path(tables, "T03_cumulative_curve.csv"))
  fwrite(data.table(observed_grids = nrow(grids), active_grids = n,
                    zero_fishing_grids = nrow(grids) - n, global_fishing_hours = total,
                    annual_area_fishing_hours = sum(areas$fishing_hours)),
         file.path(tables, "A_reconciliation.csv"))
  list(paths = paths, areas = areas, peak = peak, cutoffs = cutoffs,
       observed = nrow(grids), active = n, zero = nrow(grids) - n, total = total)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (!length(args) || length(args) > 2L) {
    stop("Usage: Rscript analysis_A.R EXTRACTED_SHARED_DIRECTORY [OUTPUT_DIRECTORY]")
  }
  invisible(run_a(args[[1L]], if (length(args) == 2L) args[[2L]] else "results"))
}
