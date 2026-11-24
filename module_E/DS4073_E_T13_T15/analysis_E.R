# =============================================================================
# DS4073 member E - hotspot synthesis (T13-T15)
# The Invisible Ocean | 2023 Global Fishing Watch visual analytics
# =============================================================================
# This script answers three questions from one reconciled pipeline:
#   T13  Which 0.1-degree grid cells are persistently in the monthly top 1%
#        of active cells, and which only spike in a few months?
#        -> figures/T13_persistence_map.png
#   T14  Which flag x geartype combinations drive two contrasting hotspots?
#        -> figures/T14_hotspot_composition.png
#   T15  How do the two hotspots monthly trajectories compare with the global
#        monthly benchmark? -> figures/T15_monthly_comparison.png
#
# Inputs (read-only, under SHARED_DIR):
#   data/grid_lookup.rds            grid_id -> lat_center/lon_center/area_code
#   data/summary/annual_grid.rds    grid_id, hours, fishing_hours
#   data/summary/monthly_global.csv date, hours, fishing_hours
#   data/monthly_grid/2023-MM.rds   (12 files)
#   data/detail/2023-MM.rds         (12 files)
#   assets/ne_110m_land.zip         Natural Earth 110m land (self-contained copy)
#
# Outputs (under OUTPUT_DIR):
#   figures/T13_persistence_map.png, T14_hotspot_composition.png,
#           T15_monthly_comparison.png
#   tables/T13_hotspot_persistence.csv, T13_spot_checks.csv,
#          T13_leaflet_cells.csv, T13_tier_summary.csv,
#          T14_hotspot_flag_gear.csv, T14_hotspot_reconciliation.csv,
#          T14_macro_structure.csv,
#          T15_hotspot_monthly_share.csv, T15_reconciliation.csv,
#          T15_monthly_deviation.csv, E_reconciliation.csv
#
# Run:
#   Rscript analysis_E.R [SHARED_DIR] [OUTPUT_DIR]
#   SHARED_DIR defaults to ../../DS4073_GFW_2023_Shared
#   OUTPUT_DIR defaults to results
#
# Packages: data.table (fast joins and aggregation), ggplot2 + scales (plots),
#           sf (read the Natural Earth land polygons).
# =============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(scales)
  library(sf)
})

source_line <- 'Source: Global Fishing Watch v3.0, 2023'
GLOBAL_TOTAL <- 111712128.6941
MONTHS <- sprintf('2023-%02d', 1:12)
MONTH_LABELS <- month.abb

# Formatting helpers ----------------------------------------------------------
hours_format <- function(x, digits = 0L) {
  formatC(x, format = 'f', digits = digits, big.mark = ',')
}
percent_format <- function(x, digits = 2L) {
  sprintf(paste0('%.', digits, 'f%%'), 100 * x)
}
# geartype == fishing means the gear was not specified; keep it separate.
display_gear <- function(x) {
  ifelse(x == 'fishing', 'Unspecified fishing', gsub('_', ' ', x))
}

# Shared ggplot theme (mirrors module_A a_theme for cross-module consistency) -
e_theme <- function() {
  theme_minimal(base_size = 13) +
    theme(
      plot.background = element_rect(fill = '#FFFFFF', colour = NA),
      plot.title = element_text(colour = '#172F40', face = 'bold', size = 20),
      plot.subtitle = element_text(colour = '#425D6D', size = 11,
                                   margin = margin(b = 14)),
      plot.caption = element_text(colour = '#506978', hjust = 0, size = 9,
                                  margin = margin(t = 10)),
      axis.title = element_text(colour = '#25475A'),
      axis.text = element_text(colour = '#25475A', size = 10),
      panel.grid.minor = element_blank(),
      plot.margin = margin(16, 20, 14, 18)
    )
}

# Read Natural Earth 110m land into a plottable data.table --------------------
read_land <- function(land_zip) {
  files <- unzip(land_zip, list = TRUE)$Name
  shp_dir <- tempfile('ne_land_')
  dir.create(shp_dir)
  unzip(land_zip, files = files[grepl('[.](shp|shx|dbf|prj)$', files)],
        exdir = shp_dir)
  land <- sf::st_read(file.path(shp_dir, 'ne_110m_land.shp'), quiet = TRUE)
  geometry <- sf::st_cast(sf::st_geometry(land), 'MULTIPOLYGON')
  xy <- as.data.table(sf::st_coordinates(geometry))
  xy[, polygon := paste(L3, L2, sep = '_')]
  xy
}

# T13 figure: discrete persistence map ---------------------------------------
plot_persistence <- function(grid_persist, land_xy, persist_colors,
                             box_rects, box_lbls) {
  ggplot() +
    geom_polygon(data = land_xy, aes(X, Y, group = polygon, subgroup = L1),
                 fill = '#E7E5DE', colour = '#A7B1B2', linewidth = 0.17) +
    geom_raster(data = grid_persist, aes(lon_center, lat_center, fill = tier)) +
    geom_rect(data = box_rects,
              aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
                  colour = color),
              fill = NA, linetype = 'dashed', linewidth = 0.7,
              inherit.aes = FALSE, show.legend = FALSE) +
    geom_text(data = box_lbls, aes(x = x, y = y, label = label, colour = color),
              hjust = 0, vjust = 0, size = 3.6, fontface = 'bold',
              inherit.aes = FALSE, show.legend = FALSE) +
    scale_colour_identity() +
    coord_fixed(xlim = c(-180, 180), ylim = c(-90, 90), expand = FALSE) +
    scale_x_continuous(breaks = seq(-180, 180, 60)) +
    scale_y_continuous(breaks = seq(-90, 90, 30)) +
    scale_fill_manual(values = persist_colors, drop = FALSE,
                      name = 'High-activity months') +
    labs(
      title = 'Where fishing intensity persisted across 2023',
      subtitle = 'Months a 0.1-degree cell ranked in the monthly top 1% of active cells',
      x = NULL, y = NULL,
      caption = paste(source_line,
                      '| Land: Natural Earth. Gray-blue = observed cells never in the top 1%.',
                      'Deep red = high intensity in 10-12 months.')
    ) +
    e_theme() +
    theme(
      panel.background = element_rect(fill = '#FFFFFF', colour = NA),
      panel.grid.major = element_line(colour = '#E7EDF0', linewidth = 0.25),
      legend.position = 'bottom',
      legend.title = element_text(colour = '#25475A', size = 9),
      legend.text = element_text(colour = '#25475A', size = 9)
    )
}

# T14 figure: flag x gear composition (side by side) --------------------------
plot_composition <- function(plot_data, gear_colors) {
  d <- as.data.table(plot_data)
  # Order: named combinations ascending by share within each box, then
  # Other combinations pinned last so it sits at the bottom of every facet.
  named <- d[combo != 'Other combinations']
  setorder(named, box, share)
  d[, combo := factor(combo, levels = c('Other combinations', named$combo))]
  d[, pct_label := sprintf('%.1f%%', share * 100)]
  ggplot(d, aes(x = share * 100, y = combo,
                fill = factor(gear_display, levels = names(gear_colors)))) +
    geom_col(width = 0.72) +
    geom_text(aes(label = pct_label), hjust = -0.1, size = 3,
              colour = '#293F4D') +
    facet_wrap(~box, scales = 'free_y', ncol = 1) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.18)),
                       labels = function(x) paste0(x, '%')) +
    scale_fill_manual(values = gear_colors, drop = TRUE,
                      name = 'Gear classification') +
    labs(
      title = 'What drives each hotspot fishing hours?',
      subtitle = 'Flag x gear combinations, share of each hotspot own 2023 total',
      x = 'Share of hotspot fishing hours', y = NULL,
      caption = 'Source: Global Fishing Watch v3.0, 2023 | Top 8 combinations shown; rest grouped as Other.\nUnspecified fishing is kept separate (gray).'
    ) +
    e_theme() +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(colour = '#E4ECEF', linewidth = 0.4),
      strip.text = element_text(colour = '#25475A', face = 'bold')
    )
}

# T15 figure: monthly trajectories vs global benchmark ------------------------
plot_comparison <- function(cmp, series_colors, series_linetypes) {
  ggplot(cmp, aes(x = month_label, y = share * 100, group = series,
                  colour = series, linetype = series)) +
    geom_line(linewidth = 1.05) +
    geom_point(data = cmp[is_peak == TRUE], aes(colour = series), size = 2.8) +
    geom_text(data = cmp[is_peak == TRUE], aes(label = peak_label),
              nudge_y = 1.4, size = 3.2, colour = '#293F4D',
              fontface = 'bold', show.legend = FALSE) +
    scale_colour_manual(values = series_colors, name = 'Series') +
    scale_linetype_manual(values = series_linetypes, name = 'Series') +
    scale_y_continuous(limits = c(0, 20), expand = expansion(mult = c(0, 0.02)),
                       labels = function(x) paste0(x, '%')) +
    labs(
      title = 'Monthly trajectories vs the global benchmark',
      subtitle = 'Each series is normalised to sum to 100% across the 12 months',
      x = NULL, y = 'Share of annual fishing hours',
      caption = paste(source_line, '| Global benchmark is the dashed line.')
    ) +
    e_theme() +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(colour = '#E4ECEF', linewidth = 0.4),
      legend.position = 'bottom',
      legend.key.width = grid::unit(1.6, 'cm')
    )
}

# ----------------------------------------------------------------------------
# run_e : main entry point
# ----------------------------------------------------------------------------
run_e <- function(shared_dir = file.path('..', '..', 'DS4073_GFW_2023_Shared'),
                  output_dir = 'results',
                  land_zip = 'assets/ne_110m_land.zip') {
  shared_dir <- normalizePath(shared_dir, mustWork = TRUE)
  data_dir <- file.path(shared_dir, 'data')

  figures_dir <- file.path(output_dir, 'figures')
  tables_dir <- file.path(output_dir, 'tables')
  dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

  save_plot <- function(name, plot, width, height) {
    path <- file.path(figures_dir, paste0(name, '.png'))
    ggsave(path, plot, width = width, height = height, dpi = 210, bg = 'white')
    path
  }
  write_csv <- function(x, name) {
    write.csv(x, file.path(tables_dir, name), row.names = FALSE, na = '')
  }

  # ---- Load shared tables ---------------------------------------------------
  lookup <- readRDS(file.path(data_dir, 'grid_lookup.rds'))
  annual_grid <- readRDS(file.path(data_dir, 'summary', 'annual_grid.rds'))
  monthly_global <- read.csv(file.path(data_dir, 'summary', 'monthly_global.csv'),
                             stringsAsFactors = FALSE, check.names = FALSE)

  # ---- Reconciliation: schema and the single global total -------------------
  stopifnot(
    all(c('grid_id', 'lat_center', 'lon_center', 'area_code') %in% names(lookup)),
    all(c('grid_id', 'hours', 'fishing_hours') %in% names(annual_grid)),
    !anyDuplicated(lookup$grid_id),
    !anyDuplicated(annual_grid$grid_id),
    nrow(lookup) == nrow(annual_grid),
    all(c('date', 'hours', 'fishing_hours') %in% names(monthly_global)),
    nrow(monthly_global) == 12L,
    identical(sort(monthly_global$date), sprintf('2023-%02d-01', 1:12)),
    abs(sum(monthly_global$fishing_hours) - GLOBAL_TOTAL) < 0.001,
    abs(sum(annual_grid$fishing_hours) - GLOBAL_TOTAL) < 0.001
  )

  # ---- Two contrasting hotspots (bounding boxes on grid centres) ------------
  # A: persistent / coastal regional hotspot (Northwest Pacific shelf).
  # B: seasonal / pelagic hotspot (Northwest Atlantic).
  boxes <- list(
    A = list(label = 'A: NW Pacific coastal shelf',
             lon = c(118, 126), lat = c(28, 38), color = '#C27D38'),
    B = list(label = 'B: NW Atlantic',
             lon = c(-75, -50), lat = c(40, 55), color = '#4C5B9E')
  )
  box_ids <- lapply(boxes, function(b) {
    lookup$grid_id[lookup$lon_center >= b$lon[1] & lookup$lon_center <= b$lon[2] &
                   lookup$lat_center >= b$lat[1] & lookup$lat_center <= b$lat[2]]
  })

  # Bounding-box overlays and callout labels for the T13 map
  box_rects <- data.frame(
    xmin = c(boxes$A$lon[1], boxes$B$lon[1]),
    xmax = c(boxes$A$lon[2], boxes$B$lon[2]),
    ymin = c(boxes$A$lat[1], boxes$B$lat[1]),
    ymax = c(boxes$A$lat[2], boxes$B$lat[2]),
    color = c(boxes$A$color, boxes$B$color)
  )
  box_lbls <- data.frame(
    x = c(120, -55), y = c(26.5, 38),
    label = c('Hotspot A: NW Pacific', 'Hotspot B: NW Atlantic'),
    color = c(boxes$A$color, boxes$B$color)
  )

  # ---- T13 + T15 monthly loop over monthly_grid files -----------------------
  persistence <- integer(nrow(lookup))   # aligned with lookup row order
  cutoffs <- numeric(12)                 # monthly top-1% threshold
  high_counts <- integer(12)             # number of high cells per month
  monthly_totals <- numeric(12)          # from monthly_grid, for reconciliation
  box_monthly <- matrix(0, nrow = 2, ncol = 12)  # hotspot A and B monthly hours

  for (m in seq_along(MONTHS)) {
    mg <- readRDS(file.path(data_dir, 'monthly_grid', paste0(MONTHS[m], '.rds')))
    monthly_totals[m] <- sum(mg$fishing_hours)
    active <- mg[mg$fishing_hours > 0]
    # Top-1% threshold among active cells. Ties at the cutoff are included
    # (>=), so a boundary tie is conservatively counted as a hit.
    cutoff <- quantile(active$fishing_hours, probs = 0.99, type = 7,
                       names = FALSE)
    cutoffs[m] <- cutoff
    high <- active[active$fishing_hours >= cutoff]
    high_counts[m] <- nrow(high)
    idx <- match(high$grid_id, lookup$grid_id)
    persistence[idx] <- persistence[idx] + 1L
    for (b in 1:2) {
      j <- match(mg$grid_id, box_ids[[b]])
      box_monthly[b, m] <- sum(mg$fishing_hours[!is.na(j)], na.rm = TRUE)
    }
  }

  # ---- Reconciliation: monthly totals match monthly_global and global -------
  stopifnot(
    all(abs(monthly_totals - monthly_global$fishing_hours) < 0.001),
    abs(sum(monthly_totals) - GLOBAL_TOTAL) < 0.001,
    all(cutoffs > 0), all(high_counts > 0)
  )

  # ---- Persistence table and discrete tiers ---------------------------------
  grid_persist <- data.table(
    grid_id = lookup$grid_id,
    lon_center = lookup$lon_center,
    lat_center = lookup$lat_center,
    area_code = lookup$area_code,
    persistence_months = persistence
  )
  grid_persist[, annual_hours :=
                 annual_grid$fishing_hours[match(grid_id, annual_grid$grid_id)]]
  tier_fun <- function(x) {
    ifelse(x == 0, '0',
           ifelse(x <= 3, '1-3',
                  ifelse(x <= 6, '4-6',
                         ifelse(x <= 9, '7-9', '10-12'))))
  }
  grid_persist[, tier := factor(tier_fun(persistence_months),
                                levels = c('0', '1-3', '4-6', '7-9', '10-12'))]

  tier_summary <- grid_persist[, .(n_cells = .N, annual_hours = sum(annual_hours)),
                               by = tier]
  tier_summary <- tier_summary[order(match(tier,
                                           c('0', '1-3', '4-6', '7-9', '10-12')))]
  tier_summary[, share_of_global := annual_hours / GLOBAL_TOTAL]
  stopifnot(abs(sum(tier_summary$annual_hours) - GLOBAL_TOTAL) < 0.001)

  # ---- Select spot-check cells ----------------------------------------------
  hot <- grid_persist[persistence_months >= 1]
  setorder(hot, -persistence_months, -annual_hours)
  persist_pick <- copy(hot[seq_len(min(2, nrow(hot)))])
  persist_pick[, role := 'persistent']
  pulse <- hot[persistence_months == 1]
  setorder(pulse, -annual_hours)
  pulse_pick <- copy(pulse[seq_len(min(2, nrow(pulse)))])
  pulse_pick[, role := 'pulse']
  mid <- hot[persistence_months >= 5 & persistence_months <= 7]
  setorder(mid, -annual_hours)
  mid_pick <- if (nrow(mid) > 0) { mm <- copy(mid[1]); mm[, role := 'intermittent']; mm } else NULL
  spot <- rbindlist(list(persist_pick, pulse_pick, mid_pick), fill = TRUE)

  # ---- T14 + spot-check loop over detail files ------------------------------
  acc <- list(list(), list())
  spot_ids <- spot$grid_id
  spot_monthly <- matrix(0, nrow = length(spot_ids), ncol = 12)
  for (m in seq_along(MONTHS)) {
    d <- readRDS(file.path(data_dir, 'detail', paste0(MONTHS[m], '.rds')))
    for (b in 1:2) {
      j <- match(d$grid_id, box_ids[[b]])
      s <- d[!is.na(j)]
      if (nrow(s) > 0) {
        acc[[b]][[m]] <- s[, .(hours = sum(fishing_hours)),
                           by = .(flag_group, geartype)]
      }
    }
    j2 <- match(d$grid_id, spot_ids)
    s2 <- d[!is.na(j2)]
    if (nrow(s2) > 0) {
      agg2 <- s2[, .(hours = sum(fishing_hours)), by = grid_id]
      k <- match(agg2$grid_id, spot_ids)
      spot_monthly[k, m] <- agg2$hours
    }
  }

  # ---- T14: flag x gear tables and reconciliation ----------------------------
  flag_gear <- lapply(1:2, function(b) {
    tab <- rbindlist(acc[[b]])
    tot <- tab[, .(hours = sum(hours)), by = .(flag_group, geartype)]
    setorder(tot, -hours)
    tot
  })
  box_detail_totals <- vapply(flag_gear, function(t) sum(t$hours), numeric(1))
  box_annual <- rowSums(box_monthly)
  stopifnot(all(abs(box_detail_totals - box_annual) < 1e-4))

  # Gear colour keys use the DISPLAY names (spaces), so every bar matches an
  # explicit colour and no NA appears in the legend. Unused levels are dropped.
  gear_colors <- c(
    'Unspecified fishing' = '#8C8C8C',
    'Other combinations' = '#CBD2D6',
    'trawlers' = '#0E7478',
    'set longlines' = '#4C5B9E',
    'set gillnets' = '#C27D38',
    'fixed gear' = '#85A64D',
    'pole and line' = '#A96180',
    'drifting longlines' = '#7A9E9F',
    'pots and traps' = '#D4C8B4'
  )

  combo_tables <- list()
  plot_list <- list()
  for (b in 1:2) {
    tot <- copy(flag_gear[[b]])
    tot[, gear_display := display_gear(geartype)]
    tot[, combo := paste0(flag_group, ' - ', gear_display)]
    tot[, share := hours / sum(hours)]
    setorder(tot, -hours)
    n_top <- 8
    top_n <- min(n_top, nrow(tot))
    top <- tot[seq_len(top_n)]
    other_hours <- if (nrow(tot) > top_n) sum(tot[(top_n + 1):nrow(tot)]$hours) else 0
    top[, plot_category := combo]
    top_plot <- top[, .(box = boxes[[b]]$label, combo = plot_category,
                        gear_display = gear_display, hours = hours, share = share)]
    if (other_hours > 0) {
      top_plot <- rbind(top_plot, data.table(
        box = boxes[[b]]$label, combo = 'Other combinations',
        gear_display = 'Other combinations', hours = other_hours,
        share = other_hours / sum(flag_gear[[b]]$hours)))
    }
    top_plot[, box := factor(box)]
    plot_list[[b]] <- top_plot
    tot[, plot_category := ifelse(seq_len(.N) <= top_n, combo, 'Other combinations')]
    combo_tables[[b]] <- tot[, .(box = boxes[[b]]$label, flag_group, geartype,
                                 gear_display, combo, hours, share, plot_category)]
  }
  plot_data <- rbindlist(plot_list)
  plot_data[, box := factor(box, levels = sapply(boxes, `[[`, 'label'))]

  # ---- T15: normalised monthly series ----------------------------------------
  global_share <- monthly_global$fishing_hours / GLOBAL_TOTAL
  box_share <- box_monthly / box_annual
  stopifnot(abs(sum(global_share) - 1) < 1e-12)
  stopifnot(all(abs(rowSums(box_share) - 1) < 1e-12))

  cmp <- rbind(
    data.table(series = 'Global benchmark', month = 1:12, share = global_share),
    data.table(series = 'Hotspot A (NW Pacific)', month = 1:12,
               share = box_share[1, ]),
    data.table(series = 'Hotspot B (NW Atlantic)', month = 1:12,
               share = box_share[2, ])
  )
  cmp[, series := factor(series, levels = c('Global benchmark',
                                            'Hotspot A (NW Pacific)',
                                            'Hotspot B (NW Atlantic)'))]
  cmp[, month_label := factor(MONTH_LABELS[month], levels = MONTH_LABELS)]
  cmp[, is_peak := share == max(share), by = series]
  cmp[, peak_label := ifelse(is_peak,
                             sprintf('%s (%.1f%%)', month_label, share * 100),
                             NA_character_)]

  series_colors <- c('Global benchmark' = '#263B47',
                     'Hotspot A (NW Pacific)' = boxes$A$color,
                     'Hotspot B (NW Atlantic)' = boxes$B$color)
  series_linetypes <- c('Global benchmark' = 'dashed',
                        'Hotspot A (NW Pacific)' = 'solid',
                        'Hotspot B (NW Atlantic)' = 'solid')

  # ---- Build figures ---------------------------------------------------------
  land_xy <- read_land(land_zip)
  persist_colors <- c('0' = '#DCE6EE', '1-3' = '#F6DCA4', '4-6' = '#EC9F5B',
                      '7-9' = '#C96A37', '10-12' = '#7C2F1B')
  paths <- c(
    T13 = save_plot('T13_persistence_map',
                    plot_persistence(grid_persist, land_xy, persist_colors,
                                     box_rects, box_lbls), 12, 7.35),
    T14 = save_plot('T14_hotspot_composition',
                    plot_composition(plot_data, gear_colors), 10.4, 7.5),
    T15 = save_plot('T15_monthly_comparison',
                    plot_comparison(cmp, series_colors, series_linetypes),
                    10.4, 6.2)
  )

  # ---- Export audit CSVs -----------------------------------------------------
  out13 <- grid_persist[persistence_months >= 1]
  setorder(out13, -persistence_months, -annual_hours)
  write_csv(as.data.frame(out13[, .(grid_id, lon_center, lat_center, area_code,
                                    persistence_months, annual_hours)]),
            'T13_hotspot_persistence.csv')

  spot_df <- as.data.frame(spot)
  for (m in 1:12) {
    mm <- sprintf('%02d', m)
    spot_df[[paste0('m', mm, '_hours')]] <- spot_monthly[, m]
    spot_df[[paste0('m', mm, '_hit')]] <-
      as.integer(spot_monthly[, m] > 0 & spot_monthly[, m] >= cutoffs[m])
  }
  hit_cols <- grep('_hit$', names(spot_df), value = TRUE)
  stopifnot(all(rowSums(spot_df[, hit_cols, drop = FALSE]) == spot_df$persistence_months))
  write_csv(spot_df, 'T13_spot_checks.csv')

  write_csv(rbindlist(combo_tables), 'T14_hotspot_flag_gear.csv')
  t14_rec <- data.frame(
    hotspot = sapply(boxes, `[[`, 'label'),
    lon_min = sapply(boxes, function(b) b$lon[1]),
    lon_max = sapply(boxes, function(b) b$lon[2]),
    lat_min = sapply(boxes, function(b) b$lat[1]),
    lat_max = sapply(boxes, function(b) b$lat[2]),
    n_cells = vapply(box_ids, length, integer(1)),
    detail_total_hours = box_detail_totals,
    grid_total_hours = box_annual,
    global_share = box_annual / GLOBAL_TOTAL,
    n_combos = vapply(flag_gear, nrow, integer(1))
  )
  write_csv(t14_rec, 'T14_hotspot_reconciliation.csv')

  t15_share <- rbind(
    data.frame(series = 'Global benchmark', month = 1:12, share = global_share),
    data.frame(series = 'Hotspot A', month = 1:12, share = box_share[1, ]),
    data.frame(series = 'Hotspot B', month = 1:12, share = box_share[2, ])
  )
  write_csv(t15_share, 'T15_hotspot_monthly_share.csv')
  t15_rec <- data.frame(
    series = c('Global benchmark', 'Hotspot A', 'Hotspot B'),
    annual_hours = c(GLOBAL_TOTAL, box_annual[1], box_annual[2]),
    monthly_share_sum = c(sum(global_share), rowSums(box_share))
  )
  write_csv(t15_rec, 'T15_reconciliation.csv')

  e_rec <- data.frame(
    metric = c('global_fishing_hours', 'months', 'observed_cells',
               'active_cells_annual', 'tier_0_cells', 'tier_1_3_cells',
               'tier_4_6_cells', 'tier_7_9_cells', 'tier_10_12_cells',
               'hotspot_A_hours', 'hotspot_B_hours',
               'monthly_totals_reconcile', 'detail_vs_grid_reconcile',
               'spot_check_hits_reconcile'),
    value = c(sprintf('%.4f', GLOBAL_TOTAL), 12, nrow(lookup),
              sum(annual_grid$fishing_hours > 0),
              as.integer(tier_summary$n_cells[1]), as.integer(tier_summary$n_cells[2]),
              as.integer(tier_summary$n_cells[3]), as.integer(tier_summary$n_cells[4]),
              as.integer(tier_summary$n_cells[5]),
              sprintf('%.4f', box_annual[1]), sprintf('%.4f', box_annual[2]),
              'TRUE', 'TRUE', 'TRUE')
  )
  write_csv(e_rec, 'E_reconciliation.csv')

  # ---- Export lightweight pre-aggregated tables for flexdashboard ------------
  # 1. T13_leaflet_cells.csv (persistence_months >= 7)
  leaflet_cells <- grid_persist[persistence_months >= 7]
  setorder(leaflet_cells, -persistence_months, -annual_hours)
  write_csv(as.data.frame(leaflet_cells[, .(grid_id, lon_center, lat_center,
                                            persistence_months, annual_hours)]),
            'T13_leaflet_cells.csv')

  # 2. T13_tier_summary.csv (5 persistence tiers)
  total_cells <- sum(tier_summary$n_cells)
  t13_tier_out <- data.frame(
    tier = as.character(tier_summary$tier),
    cell_count = as.integer(tier_summary$n_cells),
    cell_share = tier_summary$n_cells / total_cells,
    annual_hours = tier_summary$annual_hours,
    hours_share = tier_summary$share_of_global,
    stringsAsFactors = FALSE
  )
  stopifnot(
    nrow(t13_tier_out) == 5L,
    sum(t13_tier_out$cell_count) == nrow(lookup),
    abs(sum(t13_tier_out$cell_share) - 1) < 1e-12,
    abs(sum(t13_tier_out$hours_share) - 1) < 1e-12
  )
  write_csv(t13_tier_out, 'T13_tier_summary.csv')

  # 3. T14_macro_structure.csv (100% stacked Gear and Flag breakdowns)
  named_gears <- c('trawlers', 'Unspecified fishing', 'set gillnets',
                   'set longlines', 'fixed gear', 'pole and line')
  named_flags <- c('CHN', 'CAN', 'USA', 'UNKNOWN')
  macro_list <- list()
  for (b in 1:2) {
    fg_b <- copy(flag_gear[[b]])
    fg_b[, gear_display := display_gear(geartype)]
    fg_b[, gear_cat := ifelse(gear_display %in% named_gears, gear_display, 'Other gears')]
    gear_agg <- fg_b[, .(hours = sum(hours)), by = .(category = gear_cat)]
    gear_agg <- merge(data.table(category = c(named_gears, 'Other gears')),
                      gear_agg, by = 'category', all.x = TRUE, sort = FALSE)
    gear_agg[is.na(hours), hours := 0]
    gear_agg[, `:=`(hotspot = boxes[[b]]$label,
                    dimension = 'Gear',
                    share = hours / box_annual[b])]

    fg_b[, flag_cat := ifelse(flag_group %in% named_flags, flag_group, 'Other flags')]
    flag_agg <- fg_b[, .(hours = sum(hours)), by = .(category = flag_cat)]
    flag_agg <- merge(data.table(category = c(named_flags, 'Other flags')),
                      flag_agg, by = 'category', all.x = TRUE, sort = FALSE)
    flag_agg[is.na(hours), hours := 0]
    flag_agg[, `:=`(hotspot = boxes[[b]]$label,
                    dimension = 'Flag',
                    share = hours / box_annual[b])]

    stopifnot(
      abs(sum(gear_agg$share) - 1) < 1e-12,
      abs(sum(flag_agg$share) - 1) < 1e-12
    )
    macro_list[[length(macro_list) + 1L]] <- gear_agg[, .(hotspot, dimension, category, hours, share)]
    macro_list[[length(macro_list) + 1L]] <- flag_agg[, .(hotspot, dimension, category, hours, share)]
  }
  write_csv(as.data.frame(rbindlist(macro_list)), 'T14_macro_structure.csv')

  # 4. T15_monthly_deviation.csv (monthly share and deviation in percentage points)
  t15_dev <- rbind(
    data.frame(
      hotspot = 'Hotspot A (NW Pacific)',
      month = 1:12,
      month_label = MONTH_LABELS,
      share = box_share[1, ],
      global_share = global_share,
      deviation_pp = (box_share[1, ] - global_share) * 100,
      stringsAsFactors = FALSE
    ),
    data.frame(
      hotspot = 'Hotspot B (NW Atlantic)',
      month = 1:12,
      month_label = MONTH_LABELS,
      share = box_share[2, ],
      global_share = global_share,
      deviation_pp = (box_share[2, ] - global_share) * 100,
      stringsAsFactors = FALSE
    )
  )
  stopifnot(
    abs(sum(t15_dev$deviation_pp[t15_dev$hotspot == 'Hotspot A (NW Pacific)'])) < 1e-9,
    abs(sum(t15_dev$deviation_pp[t15_dev$hotspot == 'Hotspot B (NW Atlantic)'])) < 1e-9
  )
  write_csv(t15_dev, 'T15_monthly_deviation.csv')

  writeLines(sprintf('E done. Global total = %s hours', hours_format(GLOBAL_TOTAL, 4)))
  writeLines(sprintf('Persistent cells (10-12 months): %s',
                     hours_format(tier_summary$n_cells[5])))
  writeLines(sprintf('Hotspot A = %s hours (%s of global)',
                     hours_format(box_annual[1]), percent_format(box_annual[1] / GLOBAL_TOTAL)))
  writeLines(sprintf('Hotspot B = %s hours (%s of global)',
                     hours_format(box_annual[2]), percent_format(box_annual[2] / GLOBAL_TOTAL)))
  writeLines(sprintf('Output: %s', normalizePath(output_dir)))

  invisible(list(
    paths = paths,
    global_total = GLOBAL_TOTAL,
    tier_summary = tier_summary,
    spot_checks = spot_df,
    box_labels = sapply(boxes, `[[`, 'label'),
    box_annual = box_annual,
    box_share = box_share,
    global_share = global_share,
    top_combos = lapply(flag_gear, function(t) t[1]),
    plot_data = plot_data
  ))
}

# ----------------------------------------------------------------------------
# Command-line entry point
# ----------------------------------------------------------------------------
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 2L) {
    stop('Usage: Rscript analysis_E.R [SHARED_DIR] [OUTPUT_DIR]')
  }
  shared_dir <- if (length(args) >= 1L) args[[1L]] else
    file.path('..', '..', 'DS4073_GFW_2023_Shared')
  output_dir <- if (length(args) == 2L) args[[2L]] else 'results'
  invisible(run_e(shared_dir, output_dir))
}