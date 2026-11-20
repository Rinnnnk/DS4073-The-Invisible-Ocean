# DS4073 member D: flag distribution (T10-T12). Base R scaffold.
# Run: Rscript analysis_D.R [SHARED_DIR] [OUTPUT_DIR]
# Default SHARED_DIR is ../../DS4073_GFW_2023_Shared; default OUTPUT_DIR is results.

read_csv <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

run_d <- function(shared_dir = file.path("..", "..", "DS4073_GFW_2023_Shared"),
                  output_dir = "results") {
  shared_dir <- normalizePath(shared_dir, mustWork = TRUE)
  tables_dir <- file.path(output_dir, "tables")
  figures_dir <- file.path(output_dir, "figures")
  dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

  data_dir <- file.path(shared_dir, "data")
  annual_flag <- read_csv(file.path(data_dir, "summary", "annual_flag.csv"))
  annual_flag_area <- read_csv(file.path(data_dir, "summary", "annual_flag_area.csv"))

  # --- Reconciliation: every module matches the shared 2023 total. ---
  stopifnot(
    all(c("flag_group", "fishing_hours") %in% names(annual_flag)),
    all(c("flag_group", "area_code", "fishing_hours") %in% names(annual_flag_area)),
    !anyNA(annual_flag$fishing_hours),
    all(annual_flag$fishing_hours >= 0),
    !anyDuplicated(annual_flag$flag_group)
  )
  total_hours <- sum(annual_flag$fishing_hours)
  stopifnot(abs(total_hours - 111712128.6941) < 0.001)
  stopifnot(abs(sum(annual_flag_area$fishing_hours) - total_hours) < 0.001)

  cat("D scaffold ready. Global total:",
      formatC(total_hours, format = "f", digits = 4, big.mark = ","), "hours\n")

  # --- T10: Rank vessel flags by annual estimated fishing hours. ---
  # TODO(member-d): rank annual_flag; write T10_flag_ranking.csv and
  # T10_flag_ranking.png.

  # --- T11: Show how flag activity is distributed across FAO areas. ---
  # TODO(member-d): join annual_flag_area with area_names.csv; write
  # T11_flag_area.csv and T11_flag_area.png.

  # --- T12: Top three known flags contribution per area. ---
  # TODO(member-d): exclude UNKNOWN and UNK_UNRESOLVED from the ranking but keep
  # them in the denominator; write T12_top3_flags_by_area.csv and
  # T12_top3_flags_by_area.png.

  invisible(list(shared_dir = shared_dir,
                 output_dir = normalizePath(output_dir),
                 total_hours = total_hours))
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