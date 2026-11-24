# Supplemental charts for the same three A-page tasks.
plot_a_supplements <- function(shared_dir, result, output_dir = "results") {
  input <- read_a_data(shared_dir)
  grid <- input$grids
  area <- grid[grepl("^[0-9]{2}$", area_code), .(
    active_grids = sum(fishing_hours > 0), fishing_hours = sum(fishing_hours)
  ), by = area_code]
  stopifnot(nrow(area) == 19L, all(area$active_grids > 0))
  area[, highlight := area_code %in% c("61","27","51")]
  area[, short_label := fcase(area_code == "61", "61 NW Pacific",
                              area_code == "27", "27 NE Atlantic",
                              area_code == "51", "51 W Indian Ocean", default = "")]
  # Use the same grid colours as the global map. The peak is inside the crop.
  crop <- grid[between(lon_center, 105, 145) & between(lat_center, 12, 48)]
  stopifnot(max(crop$fishing_hours) == max(grid$fishing_hours))
  shp_dir <- tempfile("land_")
  dir.create(shp_dir)
  unzip("assets/ne_110m_land.zip", exdir = shp_dir)
  land <- sf::st_read(file.path(shp_dir, "ne_110m_land.shp"), quiet = TRUE)
  closeup <- plot_annual_grid(crop, land, result$peak,
                             xlim = c(105, 145), ylim = c(12, 48), use_tiles = TRUE) +
    labs(title = "A closer look at the Northwest Pacific",
         subtitle = "105 to 145 degrees E, 12 to 48 degrees N. Same color scale as the global map.",
         caption = paste(source_line, "| Circle: highest-hour cell worldwide."))
  comparison <- ggplot(area, aes(active_grids, fishing_hours)) +
    geom_point(aes(colour = highlight), size = 3.5) +
    geom_text(data = area[highlight == TRUE], aes(label = short_label),
              hjust = 1.12, size = 3.8, colour = "#214351", check_overlap = TRUE) +
    scale_colour_manual(values = c("FALSE" = "#71919D", "TRUE" = "#126C68"), guide = "none") +
    scale_x_log10(labels = scales::label_comma(), expand = expansion(mult = c(.04,.10))) +
    scale_y_log10(labels = scales::label_number(scale_cut = scales::cut_short_scale()),
                  expand = expansion(mult = c(.07,.13))) +
    labs(title = "Regional footprint and total hours",
         subtitle = "One point per FAO marine area. Both axes use log scales.",
         x = "Active 0.1-degree cells", y = "Estimated fishing hours",
         caption = paste(source_line, "| Unmatched cells excluded from this comparison.")) +
    a_theme()
  cuts <- result$cutoffs$hours_fraction
  band <- data.table(
    name = c("Top 1%", "Next 4%", "Next 5%", "Remaining 90%"),
    share = diff(c(0, cuts, 1))
  )
  stopifnot(abs(sum(band$share) - 1) < 1e-12, all(band$share >= 0))
  band[, name := factor(name, levels = rev(name))]
  bands <- ggplot(band, aes(share, name)) +
    geom_col(aes(fill = name == "Top 1%"), width = 0.66) +
    geom_text(aes(label = percent_format(share)), hjust = -0.16, colour = "#214351", size = 4.3) +
    scale_fill_manual(values = c("TRUE" = "#176A68", "FALSE" = "#80ACAC"), guide = "none") +
    scale_x_continuous(labels = scales::label_percent(), limits = c(0, .79),
                       expand = expansion(mult = c(0, 0))) +
    labs(title = "What each rank band contributes",
         subtitle = "Four distinct groups of active cells, ordered from highest to lowest hours",
         x = "Share of all estimated fishing hours", y = NULL,
         caption = paste(source_line, "| Shares sum to 100% before rounding.")) +
    a_theme() + theme(panel.grid.major.y = element_blank())
  dir.create(file.path(output_dir, "tables"), recursive = TRUE, showWarnings = FALSE)
  fwrite(area[, .(area_code, active_grids, fishing_hours)], file.path(output_dir, "tables", "T02_region_footprint.csv"))
  fwrite(band, file.path(output_dir, "tables", "T03_rank_bands.csv"))
  paths <- file.path(output_dir, "figures", c("T01_pacific_closeup.png", "T02_region_footprint.png", "T03_rank_bands.png"))
  ggsave(paths[1], closeup, width = 10.4, height = 8.4, dpi = 170, bg = "white")
  ggsave(paths[2], comparison, width = 10.4, height = 7.0, dpi = 170, bg = "white")
  ggsave(paths[3], bands, width = 10.4, height = 6.35, dpi = 170, bg = "white")
  list(paths = paths, area = area, band = band)
}

# Offline Plotly panels. The original PNGs are also rendered for reports and slides.
interactive_a_footprint <- function(extra, result) {
  area <- copy(extra$area)
  area[, area_name := result$areas$area_name[match(area_code, result$areas$area_code)]]
  area[, tooltip := paste0("<b>FAO ", area_code, " | ", area_name, "</b>",
    "<br>Active grids: ", hours_format(active_grids),
    "<br>Estimated fishing hours: ", hours_format(fishing_hours, 2),
    "<br>Share of global hours: ", percent_format(fishing_hours / result$total))]
  chart <- plotly::plot_ly(
    area, x = ~active_grids, y = ~fishing_hours, text = ~tooltip,
    type = "scatter", mode = "markers", hoverinfo = "text",
    marker = list(size = 10, color = ifelse(area$highlight, "#126C68", "#71919D"),
                  line = list(color = "white", width = 1))
  )
  chart <- plotly::layout(chart, height = 410,
    xaxis = list(title = "Active 0.1-degree grid cells (log scale)", type = "log", dtick = 1, gridcolor = "#E3ECEF"),
    yaxis = list(title = "Estimated fishing hours (log scale)", type = "log", dtick = 1, gridcolor = "#E3ECEF"),
    margin = list(l = 78, r = 18, b = 70, t = 25), dragmode = "zoom",
    hoverlabel = list(bgcolor = "#153D48", font = list(color = "white")))
  plotly::config(chart, displaylogo = FALSE, responsive = TRUE)
}

interactive_a_curve <- function(result) {
  curve <- copy(result$curve)
  curve[, tooltip := paste0("<b>Top ", percent_format(grid_fraction), " of active cells</b>",
    "<br>Grid count: ", hours_format(rank),
    "<br>Share of total hours: ", percent_format(hours_fraction),
    "<br>Estimated fishing hours: ", hours_format(hours_fraction * result$total, 2))]
  cuts <- copy(result$cutoffs)
  cuts[, tooltip := paste0("<b>Top ", top_grid_percent, "% cutoff</b>",
    "<br>Grid count: ", hours_format(grids),
    "<br>Share of total hours: ", percent_format(hours_fraction),
    "<br>Estimated fishing hours: ", hours_format(fishing_hours, 2))]
  chart <- plotly::plot_ly()
  chart <- plotly::add_lines(chart, x = c(0, 1), y = c(0, 1), hoverinfo = "skip",
    line = list(color = "#8397A2", dash = "dash", width = 1), showlegend = FALSE)
  chart <- plotly::add_lines(chart, data = curve, x = ~grid_fraction, y = ~hours_fraction,
    text = ~tooltip, hoverinfo = "text", line = list(color = "#167970", width = 3),
    showlegend = FALSE)
  chart <- plotly::add_markers(chart, data = cuts, x = ~grid_fraction, y = ~hours_fraction,
    text = ~tooltip, hoverinfo = "text", marker = list(color = "#A95730", size = 9),
    showlegend = FALSE)
  chart <- plotly::layout(chart, height = 420, dragmode = "zoom", hovermode = "closest",
    xaxis = list(title = "Cumulative share of active grid cells", tickformat = ".0%", range = c(0, 1)),
    yaxis = list(title = "Cumulative share of fishing hours", tickformat = ".0%", range = c(0, 1.02)),
    margin = list(l = 76, r = 14, b = 64, t = 58),
    updatemenus = list(list(type = "buttons", direction = "right", x = 0, y = 1.17,
      buttons = list(
        list(label = "All cells", method = "relayout",
             args = list(list("xaxis.range" = c(0, 1), "yaxis.range" = c(0, 1.02)))),
        list(label = "Top 10%", method = "relayout",
             args = list(list("xaxis.range" = c(0, .102), "yaxis.range" = c(0, 1.02))))
      ))),
    hoverlabel = list(bgcolor = "#153D48", font = list(color = "white")))
  plotly::config(chart, displaylogo = FALSE, responsive = TRUE)
}
