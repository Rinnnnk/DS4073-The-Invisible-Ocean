# DS4073 | The Invisible Ocean | B. Monthly change (T04-T06)
# Run: Rscript analysis_B.R PATH_TO_EXTRACTED_SHARED_DIRECTORY [OUTPUT_DIRECTORY]
suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(scales)
})

ocean <- "#126E79"
coral <- "#A54535"
gold <- "#9B621C"
ink <- "#182E3D"
muted <- "#45616D"
paper <- "#FFFFFF"
gridline <- "#DFE8EB"
source_b <- "Source: Global Fishing Watch v3.0, 2023. Estimated fishing hours from AIS observations."

theme_b <- function() {
  theme_minimal(base_size = 13) +
    theme(
      text = element_text(colour = ink),
      plot.title = element_text(size = 22, face = "bold", margin = margin(b = 7)),
      plot.subtitle = element_text(size = 12, colour = muted, margin = margin(b = 12)),
      plot.caption = element_text(size = 9, colour = muted, hjust = 0,
                                  lineheight = 1.15, margin = margin(t = 10)),
      plot.title.position = "plot", plot.caption.position = "plot",
      axis.title = element_text(colour = muted), axis.text = element_text(colour = ink),
      panel.grid.major = element_line(colour = gridline, linewidth = .35),
      panel.grid.minor = element_blank(),
      plot.background = element_rect(fill = paper, colour = NA),
      plot.margin = margin(16, 20, 14, 20)
    )
}

read_b_data <- function(shared_dir) {
  data_dir <- file.path(shared_dir, "data")
  monthly <- fread(file.path(data_dir, "summary", "monthly_global.csv"))
  areas <- fread(file.path(data_dir, "summary", "monthly_area.csv"),
                 colClasses = c(area_code = "character"))
  names <- fread(file.path(data_dir, "area_names.csv"), colClasses = "character")
  monthly[, date := as.IDate(date)]
  areas[, date := as.IDate(date)]
  setorder(monthly, date)
  stopifnot(nrow(monthly) == 12L, !anyDuplicated(monthly$date),
            all(as.Date(monthly$date) ==
                      seq(as.Date("2023-01-01"), as.Date("2023-12-01"), by = "month")),
            !anyDuplicated(areas, by = c("date", "area_code")),
            !anyDuplicated(names$area_code), all(areas$date %in% monthly$date),
            all(areas$area_code %in% names$area_code),
            all(is.finite(monthly$fishing_hours)), all(monthly$fishing_hours > 0),
            all(is.finite(areas$fishing_hours)), all(areas$fishing_hours >= 0))
  reconciled <- areas[, .(area_sum = sum(fishing_hours)), by = date][monthly, on = "date"]
  stopifnot(all(abs(reconciled$area_sum - reconciled$fishing_hours) < 1e-4))
  list(monthly = monthly, areas = areas, names = names)
}

build_b_results <- function(shared_dir) {
  inputs <- read_b_data(shared_dir)
  monthly <- inputs$monthly
  annual_hours <- sum(monthly$fishing_hours)
  stopifnot(abs(annual_hours - 111712128.6941) < 0.001)
  # The start of the following month gives the exact calendar-day denominator.
  monthly[, days := as.integer(diff(c(as.Date(date), as.Date("2024-01-01"))))]
  stopifnot(sum(monthly$days) == 365L, monthly$days[2] == 28L)
  monthly[, `:=`(month = month.abb[seq_len(.N)], hours_per_day = fishing_hours / days,
                annual_share = fishing_hours / annual_hours)]
  monthly[, `:=`(total_rank = frank(-fishing_hours, ties.method = "min"),
                daily_rank = frank(-hours_per_day, ties.method = "min"))]
  monthly[, rank_gain := total_rank - daily_rank]

  # Code 61 is the Northwest Pacific. Subtract its monthly totals from the
  # global series; the remainder still includes unmatched grid centres.
  northwest <- inputs$areas[area_code == "61", .(date, northwest_hours = fishing_hours)]
  stopifnot(nrow(northwest) == nrow(monthly))
  monthly[northwest, on = "date", northwest_hours := i.northwest_hours]
  monthly[, outside_northwest_hours := fishing_hours - northwest_hours]
  stopifnot(!anyNA(monthly$northwest_hours), all(monthly$outside_northwest_hours >= 0))

  # Preserve missing area-months as NA; keep the source's observed zeroes.
  official <- inputs$areas[grepl("^[0-9]{2}$", area_code)]
  codes <- sort(unique(official$area_code))
  area_month <- official[CJ(area_code = codes, date = monthly$date), on = .(area_code, date)]
  area_month[inputs$names, on = "area_code", area_name := i.area_name]
  area_month[, `:=`(observed_months = sum(!is.na(fishing_hours)),
                   area_annual_hours = sum(fishing_hours, na.rm = TRUE)), by = area_code]
  area_month[, recorded_share := fifelse(
    area_annual_hours > 0, fishing_hours / area_annual_hours, NA_real_
  )]
  area_month[, is_peak := {
    values <- fishing_hours
    !is.na(values) & values == max(values, na.rm = TRUE) & max(values, na.rm = TRUE) > 0
  }, by = area_code]
  area_month[, month_number := match(date, monthly$date)]

  peaks <- area_month[is_peak == TRUE, .(
    area_name = area_name[1L], observed_months = observed_months[1L],
    area_annual_hours = area_annual_hours[1L], peak_months = paste(month.abb[month_number], collapse = ", "),
    peak_hours = fishing_hours[1L], peak_share = recorded_share[1L]
  ), by = area_code][order(-area_annual_hours)]
  share_check <- area_month[area_annual_hours > 0, .(shares = sum(recorded_share, na.rm = TRUE)), by = area_code]
  stopifnot(all(abs(share_check$shares - 1) < 1e-10))
  list(monthly = monthly, area_month = area_month, peaks = peaks, annual_hours = annual_hours,
       unmatched_hours = sum(inputs$areas[!grepl("^[0-9]{2}$", area_code), fishing_hours]))
}

plot_b_monthly <- function(result) {
  m <- copy(result$monthly)
  m[, month_number := seq_len(.N)]
  peak <- m[which.max(fishing_hours)]
  low <- m[which.min(fishing_hours)]
  avg_millions <- result$annual_hours / (12 * 1e6)
  ggplot(m, aes(month_number, fishing_hours / 1e6)) +
    geom_area(fill = "#DCEFF0", alpha = .75) +
    geom_hline(yintercept = avg_millions, colour = "#68818C", linetype = "dashed", linewidth = .65) +
    geom_line(colour = ocean, linewidth = 1.2) +
    geom_point(colour = ocean, fill = paper, shape = 21, stroke = .9, size = 3.1) +
    geom_point(data = rbind(peak, low), colour = coral, size = 3.4) +
    annotate("text", x = 1, y = avg_millions, label = sprintf("Monthly mean  %.2f M", avg_millions),
             hjust = 0, vjust = -.65, colour = muted, size = 3.7) +
    geom_text(data = peak, aes(label = sprintf("%s  %.2f M", month, fishing_hours / 1e6)),
              vjust = -1.1, colour = coral, fontface = "bold", size = 4.2) +
    geom_text(data = low, aes(label = sprintf("%s  %.2f M", month, fishing_hours / 1e6)),
              vjust = 1.65, colour = coral, fontface = "bold", size = 4.2) +
    scale_x_continuous(breaks = 1:12, labels = month.abb, expand = expansion(add = .18)) +
    scale_y_continuous(breaks = seq(0, 14, 2), limits = c(0, 15.6), expand = expansion(mult = 0)) +
    labs(title = "When was global fishing activity highest?",
         subtitle = sprintf("The October peak was %.2f times the May low.", peak$fishing_hours / low$fishing_hours),
         x = "Month in 2023", y = "Estimated fishing hours (millions)", caption = source_b) +
    theme_b() + theme(panel.grid.major.x = element_blank())
}

plot_b_daily_rank <- function(result) {
  m <- copy(result$monthly)
  total_peak <- m[which.max(fishing_hours)]
  daily_peak <- m[which.max(hours_per_day)]
  leaders <- c(total_peak$month, daily_peak$month)
  m[, colour_key := fifelse(month %in% leaders, month, "Other")]
  ranking <- melt(m, id.vars = c("month", "colour_key"), measure.vars = c("total_rank", "daily_rank"),
                  variable.name = "basis", value.name = "rank")
  ranking[, step := as.integer(basis)]
  ranking <- ranking[order(colour_key != "Other", step)]
  colours <- c(setNames(c(coral, ocean), leaders), Other = "#677B86")
  ggplot(ranking, aes(step, rank, group = month, colour = colour_key)) +
    geom_line(aes(linewidth = colour_key == "Other")) +
    geom_point(aes(size = colour_key == "Other")) +
    geom_text(data = ranking[step == 1L], aes(label = month), nudge_x = -.045, hjust = 1, size = 3.75) +
    geom_text(data = ranking[step == 2L], aes(label = month), nudge_x = .045, hjust = 0, size = 3.75) +
    scale_colour_manual(values = colours, guide = "none") +
    scale_linewidth_manual(values = c(`TRUE` = .55, `FALSE` = 1.45), guide = "none") +
    scale_size_manual(values = c(`TRUE` = 1.6, `FALSE` = 3.3), guide = "none") +
    scale_y_reverse(breaks = 1:12, limits = c(12.45, .55)) +
    scale_x_continuous(breaks = 1:2, labels = c("Monthly total", "Hours per calendar day"),
                       limits = c(.80, 2.20), expand = expansion(mult = 0)) +
    labs(
      title = "Does adjusting for month length change the peak?",
      subtitle = sprintf("%s leads on total hours (%.2f M). %s leads after adjustment (%.1f k hours per day).",
                         total_peak$month, total_peak$fishing_hours / 1e6,
                         daily_peak$month, daily_peak$hours_per_day / 1e3),
      x = NULL, y = "Month rank (1 = highest)",
      caption = paste(source_b, "Adjustment: divide the monthly total by the number of days in that month.",
                      sep = "\n")
    ) +
    theme_b() + theme(panel.grid.major.x = element_blank(), axis.text.x = element_text(face = "bold"))
}

plot_b_area_heatmap <- function(result) {
  a <- copy(result$area_month)
  labels <- result$peaks[, sprintf("%s  %s%s", area_code, area_name,
                                   ifelse(observed_months < 12L, " *", ""))]
  area_labels <- setNames(labels, result$peaks$area_code)
  a[, area := factor(area_labels[area_code], levels = rev(labels))]
  shown_complete <- result$peaks[observed_months == 12L]
  n_peaks <- uniqueN(a[observed_months == 12L & is_peak == TRUE, month_number])
  ggplot(a, aes(month_number, area)) +
    geom_tile(aes(fill = recorded_share), height = .92, width = .95) +
    geom_point(data = a[is_peak == TRUE & observed_months == 12L], shape = 21,
               size = 2.55, stroke = .65, colour = "#FFFFFF", fill = ink) +
    scale_fill_gradientn(
      colours = c("#EDF5F5", "#B6DADD", "#55A7AC", "#0D616D"),
      limits = c(0, .20), oob = squish, na.value = "#D2D8DB",
      breaks = c(0, .05, .10, .15, .20), labels = c("0%", "5%", "10%", "15%", "20%+"),
      name = "Share of recorded annual\nhours in each FAO area",
      guide = guide_colourbar(title.position = "top", barwidth = grid::unit(4, "mm"),
                              barheight = grid::unit(45, "mm"))
    ) +
    scale_x_continuous(breaks = 1:12, labels = month.abb, expand = expansion(add = .53)) +
    labs(
      title = "Did marine areas peak in the same month?",
      subtitle = sprintf("The %d FAO areas with 12 months of records peaked across %d different months.",
                         nrow(shown_complete), n_peaks),
      x = "Month in 2023", y = NULL,
      caption = paste(
        "Source: Global Fishing Watch v3.0, 2023. FAO areas assigned by grid centre; unmatched cells excluded here.",
        "Rows ordered by total hours. Dots mark all peak months for complete rows. Gray = no record.",
        "* Incomplete row: shares use the recorded months, so no full-year peak is marked.",
        sep = "\n"
      )
    ) + theme_b() +
    theme(panel.grid.major = element_blank(), legend.position = "right",
          axis.text.y = element_text(size = 10.2),
          legend.title = element_text(size = 9.2), legend.text = element_text(size = 8.8))
}

plot_b_global_contrast <- function(result) {
  m <- copy(result$monthly)
  m[, month_number := seq_len(.N)]
  comparison <- rbind(
    m[, .(month_number, month, hours = fishing_hours, series = "Global")],
    m[, .(month_number, month, hours = outside_northwest_hours, series = "Outside Northwest Pacific")]
  )
  peaks <- comparison[, .SD[which.max(hours)], by = series]
  ggplot(comparison, aes(month_number, hours / 1e6, colour = series)) +
    geom_line(linewidth = 1.12) +
    geom_point(size = 2.35) +
    geom_point(data = peaks, size = 3.6, show.legend = FALSE) +
    geom_text(data = peaks, aes(label = sprintf("%s: %.2f M", month, hours / 1e6)),
              vjust = -1.30, fontface = "bold", size = 4, show.legend = FALSE) +
    scale_colour_manual(values = c(Global = ocean, "Outside Northwest Pacific" = coral),
                        breaks = c("Global", "Outside Northwest Pacific")) +
    scale_x_continuous(breaks = seq_len(nrow(m)), labels = month.abb, expand = expansion(add = .25)) +
    scale_y_continuous(limits = c(0, max(comparison$hours) / 1e6 * 1.17), expand = expansion(mult = 0)) +
    labs(
      title = "The global peak shifts when the Northwest Pacific is removed",
      subtitle = "The global total peaked in October; the remaining grid cells peaked in July.",
      x = "Month in 2023", y = "Estimated fishing hours (millions)", colour = NULL,
      caption = paste(source_b, "Remainder = global total minus FAO area 61. It includes unmatched grid centres.",
                      sep = "\n")
    ) +
    theme_b() + theme(panel.grid.major.x = element_blank(), legend.position = "bottom")
}

run_b <- function(shared_dir, output_dir = "results") {
  result <- build_b_results(shared_dir)
  figures <- file.path(output_dir, "figures")
  tables <- file.path(output_dir, "tables")
  dir.create(figures, recursive = TRUE, showWarnings = FALSE)
  dir.create(tables, recursive = TRUE, showWarnings = FALSE)
  plots <- list(T04 = plot_b_monthly(result), T05 = plot_b_daily_rank(result), T06 = plot_b_area_heatmap(result),
                T06_contrast = plot_b_global_contrast(result))
  filenames <- c(T04 = "T04_monthly_total", T05 = "T05_daily_average", T06 = "T06_area_peaks",
                 T06_contrast = "T06_global_vs_outside_northwest")
  paths <- setNames(file.path(figures, paste0(filenames, ".png")), names(filenames))
  for (task in names(paths)) {
    height <- if (task == "T06") 7.65 else 5.5
    width <- if (task == "T06") 13.8 else 11.8
    ggsave(paths[[task]], plots[[task]], width = width, height = height, dpi = 220, bg = paper)
    ggsave(file.path(figures, paste0(filenames[[task]], ".pdf")), plots[[task]],
           width = width, height = height, device = "pdf", bg = paper)
  }
  fwrite(result$monthly, file.path(tables, "B-monthly-global-and-daily.csv"))
  fwrite(result$area_month, file.path(tables, "B-monthly-fao-areas.csv"), na = "")
  fwrite(result$peaks, file.path(tables, "B-fao-peak-months.csv"))
  result$paths <- paths
  result$plots <- plots
  result
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 2L) stop("Usage: Rscript analysis_B.R [SHARED_DIR] [OUTPUT_DIR]")
  shared_dir <- if (length(args)) args[1L] else "../../DS4073_GFW_2023_Shared"
  result <- run_b(shared_dir, if (length(args) == 2L) args[2L] else "results")
  message(sprintf("Verified %d months; %.4f estimated fishing hours.", nrow(result$monthly), result$annual_hours))
}
