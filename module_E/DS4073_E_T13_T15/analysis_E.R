# DS4073 member E: hotspot synthesis (T13-T15). Base R scaffold.
# Run: Rscript analysis_E.R [SHARED_DIR] [OUTPUT_DIR]
# Default SHARED_DIR is ../../DS4073_GFW_2023_Shared; default OUTPUT_DIR is results.

read_csv <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

run_e <- function(shared_dir = file.path("..", "..", "DS4073_GFW_2023_Shared"),
                  output_dir = "results") {
  shared_dir <- normalizePath(shared_dir, mustWork = TRUE)
  tables_dir <- file.path(output_dir, "tables")
  figures_dir <- file.path(output_dir, "figures")
  dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

  data_dir <- file.path(shared_dir, "data")
  monthly_global <- read_csv(file.path(data_dir, "summary", "monthly_global.csv"))
  monthly_grid_dir <- file.path(data_dir, "monthly_grid")
  detail_dir <- file.path(data_dir, "detail")
  months <- sprintf("2023-%02d.rds", 1:12)
  stopifnot(all(file.exists(file.path(monthly_grid_dir, months))))
  stopifnot(all(file.exists(file.path(detail_dir, months))))

  # --- Reconciliation: every module matches the shared 2023 total. ---
  stopifnot(
    all(c("date", "fishing_hours") %in% names(monthly_global)),
    nrow(monthly_global) == 12L,
    identical(sort(monthly_global$date), sprintf("2023-%02d-01", 1:12)),
    !anyNA(monthly_global$fishing_hours),
    all(monthly_global$fishing_hours >= 0)
  )
  total_hours <- sum(monthly_global$fishing_hours)
  stopifnot(abs(total_hours - 111712128.6941) < 0.001)

  cat("E scaffold ready. Global total:",
      formatC(total_hours, format = "f", digits = 4, big.mark = ","), "hours\n")

  # --- T13: Identify hotspot grid cells from the monthly grid tables. ---
  # TODO(member-e): sum monthly_grid/2023-MM.rds by grid_id, rank cells, and draw
  # the hotspot map. Write T13_hotspots.csv and T13_hotspot_map.png.

  # --- T14: Describe the flag composition of the hotspot grids. ---
  # TODO(member-e): filter data/detail by the hotspot grid_id set and aggregate
  # flag_group. Write T14_hotspot_flags.csv and T14_hotspot_flags.png.

  # --- T15: Compare hotspot gear composition with the global mix. ---
  # TODO(member-e): aggregate geartype within hotspot grids and compare with the
  # global annual gear mix. Write T15_hotspot_gears.csv and T15_hotspot_gears.png.

  invisible(list(shared_dir = shared_dir,
                 output_dir = normalizePath(output_dir),
                 total_hours = total_hours))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 2L) {
    stop("Usage: Rscript analysis_E.R [SHARED_DIR] [OUTPUT_DIR]")
  }
  shared_dir <- if (length(args) >= 1L) args[[1L]] else file.path("..", "..", "DS4073_GFW_2023_Shared")
  output_dir <- if (length(args) == 2L) args[[2L]] else "results"
  invisible(run_e(shared_dir, output_dir))
}