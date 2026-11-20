# T06 companion: Lab 9-style shared x-axis and FAO area selection.
# Source after analysis_B.R; input is the result of build_b_results() or run_b().
build_interactive_b <- function(result) {
  monthly <- result$monthly
  peak_global <- monthly[which.max(fishing_hours), date]
  peak_rest <- monthly[which.max(outside_northwest_hours), date]
  complete <- result$peaks[observed_months == 12L, .(area_code, area_name)]
  areas <- result$area_month[area_code %in% complete$area_code][order(date)]
  stopifnot(nrow(complete) > 0L, complete$area_code[1L] == "61", !anyNA(areas$recorded_share))

  ink <- "#192E39"
  ocean <- "#116C77"
  ochre <- "#A85030"
  muted <- "#526B76"
  line_grid <- "#DDE7EA"
  hours <- function(x) formatC(x, format = "f", digits = 0, big.mark = ",")
  tooltip <- function(label, dates, values, share = NULL) {
    text <- paste0("<b>", label, "</b><br>", format(dates, "%b %Y"),
                   "<br>Estimated hours: ", hours(values))
    if (!is.null(share)) text <- paste0(text, "<br>Share of recorded annual hours: ",
                                      sprintf("%.1f%%", 100 * share))
    text
  }
  make_trace <- function(fig, label, dates, y, colour, details, peak = NULL,
                         dash = "solid", visible = TRUE, legend = TRUE) {
    sizes <- if (is.null(peak)) rep(5, length(dates)) else ifelse(dates %in% peak, 10, 5)
    plotly::add_trace(fig, x = dates, y = y, type = "scatter", mode = "lines+markers",
              name = label, text = details, hovertemplate = "%{text}<extra></extra>",
              line = list(color = colour, width = 2.7, dash = dash),
              marker = list(color = colour, size = sizes),
              visible = visible, showlegend = legend, inherit = FALSE)
  }
  top <- plotly::plot_ly()
  top <- make_trace(top, "Global", monthly$date, monthly$fishing_hours / 1e6, ocean,
                    tooltip("Global", monthly$date, monthly$fishing_hours), peak_global)
  top <- make_trace(top, "Outside Northwest Pacific", monthly$date, monthly$outside_northwest_hours / 1e6, ochre,
                    tooltip("Outside Northwest Pacific", monthly$date, monthly$outside_northwest_hours), peak_rest)

  bottom <- plotly::plot_ly()
  bottom <- make_trace(bottom, "Global share", monthly$date, monthly$annual_share, muted,
                       tooltip("Global share", monthly$date, monthly$fishing_hours, monthly$annual_share),
                       dash = "dot")
  for (i in seq_len(nrow(complete))) {
    code <- complete$area_code[i]
    a <- areas[area_code == code]
    label <- paste(code, complete$area_name[i])
    bottom <- make_trace(bottom, label, a$date, a$recorded_share, ocean,
                         tooltip(label, a$date, a$fishing_hours, a$recorded_share),
                         a$date[a$recorded_share == max(a$recorded_share)],
                         visible = i == 1L, legend = FALSE)
  }

  # Lab 9 pattern: subplot uses a shared month axis and synchronizes zoom/pan.
  fig <- plotly::subplot(top, bottom, nrows = 2, shareX = TRUE, margin = .085)
  built <- plotly::plotly_build(fig)
  traces <- built$x$data
  stopifnot(length(traces) == 3L + nrow(complete),
            identical(vapply(traces[1:3], function(t) t$name, character(1)),
                      c("Global", "Outside Northwest Pacific", "Global share")))
  area_indices <- seq.int(3L, length(traces) - 1L)
  buttons <- lapply(seq_len(nrow(complete)), function(i) {
    visible <- seq_len(nrow(complete)) == i
    list(label = paste(complete$area_code[i], complete$area_name[i]),
         method = "restyle", args = list(list(visible = as.list(visible)), as.list(area_indices)))
  })
  month_ticks <- seq(as.Date("2023-01-01"), as.Date("2023-12-01"), by = "month")
  fig <- plotly::layout(
    built, autosize = TRUE, paper_bgcolor = "#FFFFFF", plot_bgcolor = "#FFFFFF",
    margin = list(l = 82, r = 30, t = 85, b = 52),
    font = list(family = "Arial, sans-serif", size = 13, color = ink),
    hovermode = "closest", legend = list(orientation = "h", x = 0, y = 1.13, font = list(size = 11)),
    xaxis = list(type = "date", tickvals = format(month_ticks), ticktext = month.abb, gridcolor = line_grid,
                 range = c("2022-12-20", "2023-12-14"), title = "Month in 2023"),
    yaxis = list(title = "Estimated hours (millions)", rangemode = "tozero", gridcolor = line_grid),
    yaxis2 = list(title = "Share of annual hours", tickformat = ".0%", rangemode = "tozero",
                  gridcolor = line_grid),
    updatemenus = list(list(type = "dropdown", buttons = buttons, active = 0,
                            x = .26, xanchor = "left", y = .51, yanchor = "middle",
                            showactive = TRUE, bgcolor = "#F0F6F7", bordercolor = "#BCD0D4")),
    annotations = list(
      list(x = 0, y = 1.017, xref = "paper", yref = "paper", xanchor = "left",
           text = "<b>1. Global and outside the Northwest Pacific</b>", showarrow = FALSE),
      list(x = 0, y = .51, xref = "paper", yref = "paper", xanchor = "left",
           text = "<b>2. Choose area</b>", showarrow = FALSE)
    )
  )
  fig$height <- 655
  plotly::config(fig, displaylogo = FALSE, responsive = TRUE,
         modeBarButtonsToRemove = c("lasso2d", "select2d"))
}
