# DS4073 member D: flag distribution (T10-T12).
# Run: Rscript analysis_D.R [SHARED_DIR] [OUTPUT_DIR]
# Default SHARED_DIR is ../../DS4073_GFW_2023_Shared; default OUTPUT_DIR is results.
#
# Inputs (small summary tables only, no detail grid files):
#   data/summary/annual_flag.csv       flag_group, hours, fishing_hours
#   data/summary/annual_flag_area.csv  flag_group, area_code, hours, fishing_hours
#   data/area_names.csv                area_code, area_name
# The measure analysed here is `fishing_hours`, the AIS-estimated apparent fishing
# time. `hours` also ships in both tables but measures AIS presence time, not fishing.

library(ggplot2)

GLOBAL_TOTAL <- 111712128.6941
UNKNOWN_FLAGS <- c("UNKNOWN", "UNK_UNRESOLVED")
source_line <- "Source: Global Fishing Watch v3.0, 2023"

hours_format <- function(x, digits = 0L) {
  formatC(x, format = "f", digits = digits, big.mark = ",")
}

percent_format <- function(x, digits = 1L) {
  sprintf(paste0("%.", digits, "f%%"), 100 * x)
}

read_csv <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

d_theme <- function() {
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

read_d_data <- function(shared_dir) {
  data_dir <- file.path(shared_dir, "data")
  flags <- read_csv(file.path(data_dir, "summary", "annual_flag.csv"))
  flag_area <- read_csv(file.path(data_dir, "summary", "annual_flag_area.csv"))
  area_names <- read_csv(file.path(data_dir, "area_names.csv"))

  stopifnot(
    all(c("flag_group", "fishing_hours") %in% names(flags)),
    all(c("flag_group", "area_code", "fishing_hours") %in% names(flag_area)),
    all(c("area_code", "area_name") %in% names(area_names)),
    !anyDuplicated(flags$flag_group),
    !anyDuplicated(area_names$area_code),
    !anyNA(flags$fishing_hours), !anyNA(flag_area$fishing_hours),
    all(flags$fishing_hours >= 0), all(flag_area$fishing_hours >= 0),
    all(flag_area$area_code %in% area_names$area_code),
    all(flag_area$flag_group %in% flags$flag_group)
  )

  total_hours <- sum(flags$fishing_hours)
  stopifnot(
    abs(total_hours - GLOBAL_TOTAL) < 1e-4,
    abs(sum(flag_area$fishing_hours) - total_hours) < 1e-4,
    nrow(flags) > 0L, nrow(flag_area) > 0L
  )

  # Every flag's area rows must add up to that flag's annual total: the two summary
  # tables are built from the same detail rows, so any gap means a broken extract.
  flag_sums <- tapply(flag_area$fishing_hours, flag_area$flag_group, sum)
  stopifnot(
    setequal(names(flag_sums), flags$flag_group),
    all(abs(flag_sums[flags$flag_group] - flags$fishing_hours) < 1e-4)
  )

  list(flags = flags, flag_area = flag_area, area_names = area_names,
       total_hours = total_hours)
}

prepare_d <- function(input) {
  flags <- input$flags
  flag_area <- input$flag_area
  total <- input$total_hours

  # T10: annual ranking. UNKNOWN and UNK_UNRESOLVED stay in the ranking and are
  # flagged instead of dropped, so the chart shows how much of the ocean is unlabeled.
  flags$is_unknown <- flags$flag_group %in% UNKNOWN_FLAGS
  flags <- flags[order(-flags$fishing_hours, flags$flag_group), ]
  flags$rank <- seq_len(nrow(flags))
  flags$share_of_global <- flags$fishing_hours / total
  flags$cumulative_share <- cumsum(flags$share_of_global)
  flags$category <- ifelse(flags$flag_group == "CHN", "China",
                           ifelse(flags$is_unknown, "Unknown flag", "Other flag"))
  rownames(flags) <- NULL

  # Areas: 19 FAO major areas plus the unmatched bucket. AMBIGUOUS exists in
  # area_names.csv but has no rows in 2023 data, so it stays a zero-hour row.
  area_total <- aggregate(fishing_hours ~ area_code, data = flag_area, FUN = sum)
  areas <- merge(input$area_names, area_total, by = "area_code", all.x = TRUE)
  areas$fishing_hours[is.na(areas$fishing_hours)] <- 0
  areas$official_area <- grepl("^[0-9]{2}$", areas$area_code)
  areas$share_of_global <- areas$fishing_hours / total
  areas <- areas[order(-areas$fishing_hours, areas$area_code), ]
  rownames(areas) <- NULL
  stopifnot(abs(sum(areas$fishing_hours) - total) < 1e-4)

  # T11: flag x area matrix, normalised within flag. Each row sums to 100%, so the
  # row answers "where does this flag fish", not "who fishes in this area" (that is T12).
  flag_area <- merge(flag_area, input$area_names, by = "area_code", all.x = TRUE)
  stopifnot(!anyNA(flag_area$area_name))
  flag_total <- setNames(flags$fishing_hours, flags$flag_group)
  flag_area$share_of_flag <- flag_area$fishing_hours / flag_total[flag_area$flag_group]
  stopifnot(all(is.finite(flag_area$share_of_flag)))

  row_check <- tapply(flag_area$share_of_flag, flag_area$flag_group, sum)
  stopifnot(all(abs(row_check - 1) < 1e-9))

  list(flags = flags, areas = areas, flag_area = flag_area, total = total)
}

plot_flag_ranking <- function(prepared, n_show = 25L) {
  flags <- prepared$flags
  shown <- head(flags, n_show)
  rest <- flags[-seq_len(nrow(shown)), ]
  bars <- data.frame(
    label = c(shown$flag_group, sprintf("Other %d flags", nrow(rest))),
    fishing_hours = c(shown$fishing_hours, sum(rest$fishing_hours)),
    share_of_global = c(shown$share_of_global, sum(rest$share_of_global)),
    category = c(shown$category, "Other flag"),
    stringsAsFactors = FALSE
  )
  bars$label <- factor(bars$label, levels = rev(bars$label))

  top3 <- head(flags, 3L)
  n80 <- which(flags$cumulative_share >= 0.8)[1]
  n90 <- which(flags$cumulative_share >= 0.9)[1]

  ggplot(bars, aes(x = fishing_hours / 1e6, y = label)) +
    geom_col(aes(fill = category), width = 0.74) +
    geom_text(aes(label = sprintf("%s  |  %s", hours_format(fishing_hours / 1e6, 1),
                                  percent_format(share_of_global))),
              hjust = -0.08, colour = "#293F4D", size = 2.9) +
    scale_fill_manual(values = c("China" = "#283B65", "Unknown flag" = "#8E9BA2",
                                 "Other flag" = "#35A98D"), name = NULL) +
    scale_x_continuous(breaks = seq(0, 60, 10),
                       expand = expansion(mult = c(0, 0.30))) +
    labs(
      title = "Which vessel flags account for the fishing hours?",
      subtitle = sprintf(paste0("Top %d flags of %d; bars are annual apparent fishing hours, ",
                                "share of the global total in the labels"),
                         nrow(shown), nrow(flags)),
      x = "Estimated fishing hours (millions)", y = NULL,
      caption = paste(
        source_line, "|",
        sprintf("%s alone is %s of global hours; %d flags reach 80%% and %d reach 90%%.",
                top3$flag_group[1], percent_format(top3$share_of_global[1]), n80, n90),
        "\nFlag labels are GFW flag groups, not verified vessel nationality.",
        "'Unknown flag' pools UNKNOWN and UNK_UNRESOLVED."
      )
    ) +
    d_theme() +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = "#E4ECEF", linewidth = 0.4),
      legend.position = "top", legend.justification = "left"
    )
}

plot_flag_area_heatmap <- function(prepared, n_flags = 24L) {
  flags <- prepared$flags
  areas <- prepared$areas
  flag_area <- prepared$flag_area

  known <- head(flags[!flags$is_unknown, ], n_flags)
  unknown <- flags[flags$is_unknown, ]
  keep <- c(known$flag_group, unknown$flag_group)
  kept <- flags[flags$flag_group %in% keep, ]
  kept <- kept[order(-kept$fishing_hours), ]

  area_keep <- areas[areas$fishing_hours > 0, ]
  area_keep <- area_keep[order(-area_keep$fishing_hours), ]
  area_keep <- rbind(area_keep[area_keep$official_area, ],
                     area_keep[!area_keep$official_area, ])

  grid <- expand.grid(flag_group = kept$flag_group, area_code = area_keep$area_code,
                      stringsAsFactors = FALSE)
  grid <- merge(grid, flag_area[, c("flag_group", "area_code", "share_of_flag",
                                    "fishing_hours")],
                by = c("flag_group", "area_code"), all.x = TRUE)
  grid$share_of_flag[is.na(grid$share_of_flag)] <- 0
  grid$fishing_hours[is.na(grid$fishing_hours)] <- 0
  grid$area_name <- area_keep$area_name[match(grid$area_code, area_keep$area_code)]
  grid$area_label <- factor(grid$area_name, levels = area_keep$area_name)
  flag_labels <- sprintf("%s  %s", kept$flag_group,
                         ifelse(kept$share_of_global >= 0.001,
                                percent_format(kept$share_of_global),
                                "<0.1%"))
  names(flag_labels) <- kept$flag_group
  grid$flag_label <- factor(flag_labels[grid$flag_group], levels = rev(flag_labels))

  stopifnot(all(tapply(grid$share_of_flag, grid$flag_group, function(x) abs(sum(x) - 1)) < 1e-9))
  grid$tile_text <- ifelse(grid$share_of_flag >= 0.10,
                           sprintf("%.0f", 100 * grid$share_of_flag), "")

  ggplot(grid, aes(x = area_label, y = flag_label, fill = share_of_flag)) +
    geom_tile(colour = "#DCE4E7", linewidth = 0.5) +
    geom_text(aes(label = tile_text), colour = "#FFFFFF", size = 2.5, fontface = "bold") +
    scale_fill_gradientn(colours = c("#FFFFFF", "#E3F4EC", "#9BDCC8", "#4CB49A",
                                     "#1B7A78", "#283B65", "#63264D"),
                         limits = c(0, 1),
                         labels = function(x) sprintf("%.0f%%", 100 * x),
                         name = "Share of the flag's\nown fishing hours",
                         guide = guide_colourbar(barwidth = grid::unit(8, "cm"),
                                                 title.position = "left")) +
    scale_x_discrete(expand = c(0, 0)) +
    scale_y_discrete(expand = c(0, 0)) +
    labs(
      title = "Each flag fishes in its own corner of the ocean",
      subtitle = sprintf(paste0("Share of each flag's annual fishing hours by FAO area; ",
                                "rows sum to 100%%, cells above 10%% are labelled")),
      x = NULL, y = NULL,
      caption = paste(
        source_line, "|",
        "Row labels carry each flag's share of global fishing hours, so a 100% row can still be tiny.",
        "\nFAO areas are assigned by grid-centre; unmatched grid centres are the last column.",
        sprintf("Shown: the %d largest flags plus unknown-flag rows.", n_flags)
      )
    ) +
    d_theme() +
    theme(
      axis.text.x = element_text(angle = 40, hjust = 1, vjust = 1, size = 8.5),
      axis.text.y = element_text(size = 8.5),
      panel.grid.major = element_blank(),
      legend.position = "bottom", legend.justification = "left",
      legend.title = element_text(colour = "#25475A", size = 9),
      legend.text = element_text(colour = "#25475A", size = 9)
    )
}

summarise_top3 <- function(prepared) {
  flag_area <- prepared$flag_area
  areas <- prepared$areas
  known <- !(flag_area$flag_group %in% UNKNOWN_FLAGS)
  codes <- areas$area_code[areas$fishing_hours > 0]

  rows <- lapply(codes, function(code) {
    cells <- flag_area[flag_area$area_code == code, ]
    area_hours <- sum(cells$fishing_hours)
    known_cells <- cells[!(cells$flag_group %in% UNKNOWN_FLAGS), ]
    known_cells <- known_cells[order(-known_cells$fishing_hours, known_cells$flag_group), ]
    unknown_hours <- sum(cells$fishing_hours[cells$flag_group %in% UNKNOWN_FLAGS])
    top <- head(known_cells, 3L)
    n_known <- sum(known_cells$fishing_hours > 0)
    pick <- function(i, field) if (nrow(top) >= i) top[[field]][i] else NA
    data.frame(
      area_code = code,
      area_name = cells$area_name[1],
      area_fishing_hours = area_hours,
      known_fishing_hours = sum(known_cells$fishing_hours),
      unknown_fishing_hours = unknown_hours,
      unknown_share = unknown_hours / area_hours,
      n_known_flags = n_known,
      top1_flag = pick(1L, "flag_group"), top1_hours = pick(1L, "fishing_hours"),
      top2_flag = pick(2L, "flag_group"), top2_hours = pick(2L, "fishing_hours"),
      top3_flag = pick(3L, "flag_group"), top3_hours = pick(3L, "fishing_hours"),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  out$top3_fishing_hours <- rowSums(cbind(out$top1_hours, out$top2_hours, out$top3_hours),
                                    na.rm = TRUE)
  out$top3_share_of_area <- out$top3_fishing_hours / out$area_fishing_hours
  out$other_known_hours <- out$known_fishing_hours - out$top3_fishing_hours
  out$official_area <- grepl("^[0-9]{2}$", out$area_code)
  out <- out[order(-out$official_area, -out$top3_share_of_area, out$area_code), ]
  rownames(out) <- NULL
  out
}

plot_top3_by_area <- function(top3, prepared) {
  d <- top3
  d$area_label <- ifelse(d$official_area,
                         paste0(d$area_code, "  ", d$area_name),
                         "Unmatched grid centres")
  d$other_known_hours[is.na(d$other_known_hours)] <- 0
  d$y <- nrow(d):1L

  part_levels <- c("Top flag", "Second flag", "Third flag",
                   "Other known flags", "Unknown flag")
  seg <- rbind(
    data.frame(area_code = d$area_code, part = "Top flag", hours = d$top1_hours,
               flag = d$top1_flag, stringsAsFactors = FALSE),
    data.frame(area_code = d$area_code, part = "Second flag", hours = d$top2_hours,
               flag = d$top2_flag, stringsAsFactors = FALSE),
    data.frame(area_code = d$area_code, part = "Third flag", hours = d$top3_hours,
               flag = d$top3_flag, stringsAsFactors = FALSE),
    data.frame(area_code = d$area_code, part = "Other known flags",
               hours = d$other_known_hours, flag = NA_character_, stringsAsFactors = FALSE),
    data.frame(area_code = d$area_code, part = "Unknown flag",
               hours = d$unknown_fishing_hours, flag = NA_character_, stringsAsFactors = FALSE)
  )
  seg$hours[is.na(seg$hours)] <- 0
  seg$part <- factor(seg$part, levels = part_levels)
  seg$area_fishing_hours <- d$area_fishing_hours[match(seg$area_code, d$area_code)]
  seg$share <- seg$hours / seg$area_fishing_hours
  seg <- seg[order(match(seg$area_code, d$area_code), seg$part), ]

  # Segment edges are computed explicitly so the stack order matches the legend:
  # the largest known flag starts at zero and the unknown share always closes the bar.
  seg$cum <- ave(seg$share, seg$area_code, FUN = cumsum)
  seg$xmax <- seg$cum
  seg$xmin <- seg$cum - seg$share
  seg$y <- d$y[match(seg$area_code, d$area_code)]
  seg$label <- ifelse(seg$share >= 0.055 & !is.na(seg$flag), seg$flag, "")
  stopifnot(abs(max(seg$cum) - 1) < 1e-9)

  ggplot() +
    geom_rect(data = seg, aes(xmin = xmin, xmax = xmax, ymin = y - 0.38, ymax = y + 0.38,
                              fill = part)) +
    geom_text(data = seg[seg$label != "", ],
              aes(x = (xmin + xmax) / 2, y = y, label = label),
              colour = "#FFFFFF", size = 2.4, fontface = "bold") +
    geom_text(data = d, aes(x = 1.012, y = y, label = percent_format(top3_share_of_area)),
              hjust = 0, colour = "#293F4D", size = 2.9) +
    scale_fill_manual(values = c("Top flag" = "#283B65", "Second flag" = "#166C78",
                                 "Third flag" = "#35A98D", "Other known flags" = "#C9D6D9",
                                 "Unknown flag" = "#63264D"), name = NULL) +
    scale_x_continuous(limits = c(0, 1.075), breaks = seq(0, 1, 0.25),
                       labels = function(x) sprintf("%.0f%%", 100 * x),
                       expand = c(0, 0)) +
    scale_y_continuous(breaks = d$y, labels = d$area_label,
                       limits = c(0.4, nrow(d) + 0.6), expand = c(0, 0)) +
    labs(
      title = "How much of each area do the three largest known flags take?",
      subtitle = paste0("Share of each area's annual fishing hours; the denominator keeps ",
                        "unknown-flag hours"),
      x = "Share of the area's annual fishing hours", y = NULL,
      caption = paste(
        source_line, "|",
        "Right-hand number: combined share of the three largest known flags.",
        "\nThe ranking excludes UNKNOWN and UNK_UNRESOLVED; the denominator keeps them.",
        "\nUnmatched grid centres are not a FAO area and are shown apart."
      )
    ) +
    d_theme() +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = "#E4ECEF", linewidth = 0.4),
      legend.position = "bottom", legend.justification = "left",
      legend.text = element_text(colour = "#25475A", size = 9),
      axis.text.y = element_text(size = 9)
    )
}

run_d <- function(shared_dir = file.path("..", "..", "DS4073_GFW_2023_Shared"),
                  output_dir = "results") {
  shared_dir <- normalizePath(shared_dir, mustWork = TRUE)
  tables_dir <- file.path(output_dir, "tables")
  figures_dir <- file.path(output_dir, "figures")
  dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

  input <- read_d_data(shared_dir)
  prepared <- prepare_d(input)
  total <- prepared$total

  cat("D inputs reconciled. Global total:",
      formatC(total, format = "f", digits = 4, big.mark = ","), "hours\n")
  cat("Flags:", nrow(prepared$flags), "| flag-area rows:", nrow(prepared$flag_area),
      "| areas with hours:", sum(prepared$areas$fishing_hours > 0), "\n")

  top3 <- summarise_top3(prepared)

  save_plot <- function(name, plot, width, height) {
    path <- file.path(figures_dir, paste0(name, ".png"))
    ggsave(path, plot, width = width, height = height, dpi = 210, bg = "white")
    path
  }

  paths <- c(
    T10 = save_plot("T10_flag_ranking", plot_flag_ranking(prepared), 10.6, 8.2),
    T11 = save_plot("T11_flag_area", plot_flag_area_heatmap(prepared), 12.6, 8.8),
    T12 = save_plot("T12_top3_flags_by_area", plot_top3_by_area(top3, prepared), 10.8, 7.8)
  )

  flags_out <- prepared$flags[, c("rank", "flag_group", "fishing_hours", "hours",
                                  "share_of_global", "cumulative_share",
                                  "is_unknown", "category")]
  write.csv(flags_out, file.path(tables_dir, "T10_flag_ranking.csv"), row.names = FALSE)

  flag_area_out <- prepared$flag_area
  flag_area_out$flag_share_of_global <-
    flag_area_out$fishing_hours / total
  flag_area_out$area_share_of_global <-
    flag_area_out$fishing_hours / prepared$areas$fishing_hours[
      match(flag_area_out$area_code, prepared$areas$area_code)]
  flag_area_out <- flag_area_out[order(flag_area_out$flag_group,
                                       -flag_area_out$fishing_hours), ]
  write.csv(flag_area_out[, c("flag_group", "area_code", "area_name", "hours",
                              "fishing_hours", "share_of_flag",
                              "flag_share_of_global", "area_share_of_global")],
            file.path(tables_dir, "T11_flag_area.csv"), row.names = FALSE)

  write.csv(top3, file.path(tables_dir, "T12_top3_flags_by_area.csv"), row.names = FALSE)

  reconcile <- data.frame(
    global_fishing_hours = total,
    reconciliation_target = GLOBAL_TOTAL,
    absolute_difference = abs(total - GLOBAL_TOTAL),
    flag_rows = nrow(prepared$flags),
    flag_area_rows = nrow(prepared$flag_area),
    areas_in_shared_table = nrow(prepared$areas),
    areas_with_hours = sum(prepared$areas$fishing_hours > 0),
    max_flag_row_deviation = max(abs(tapply(prepared$flag_area$share_of_flag,
                                            prepared$flag_area$flag_group, sum) - 1)),
    unknown_flag_hours = sum(prepared$flags$fishing_hours[prepared$flags$is_unknown]),
    unknown_flag_share = sum(prepared$flags$share_of_global[prepared$flags$is_unknown]),
    stringsAsFactors = FALSE
  )
  write.csv(reconcile, file.path(tables_dir, "D_reconciliation.csv"), row.names = FALSE)

  list(paths = paths, flags = prepared$flags, areas = prepared$areas,
       flag_area = prepared$flag_area, top3 = top3, total = total,
       reconciliation = reconcile)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 2L) {
    stop("Usage: Rscript analysis_D.R [SHARED_DIR] [OUTPUT_DIR]")
  }
  shared_dir <- if (length(args) >= 1L) args[[1L]] else file.path("..", "..", "DS4073_GFW_2023_Shared")
  output_dir <- if (length(args) == 2L) args[[2L]] else "results"
  invisible(run_d(shared_dir, output_dir))
}
