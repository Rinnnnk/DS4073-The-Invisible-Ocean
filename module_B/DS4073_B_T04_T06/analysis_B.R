# DS4073 member B: monthly variation (T04-T06). Base R scaffold.
# Run: Rscript analysis_B.R [SHARED_DIR] [OUTPUT_DIR]
# Default SHARED_DIR is ../../DS4073_GFW_2023_Shared; default OUTPUT_DIR is results.

read_csv <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

run_b <- function(shared_dir = file.path("..", "..", "DS4073_GFW_2023_Shared"),
                  output_dir = "results") {
  shared_dir <- normalizePath(shared_dir, mustWork = TRUE)
  tables_dir <- file.path(output_dir, "tables")
  figures_dir <- file.path(output_dir, "figures")
  dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(figures_dir, recursive = TRUE, showWarnings = FALSE)

  data_dir <- file.path(shared_dir, "data")
  monthly_global <- read_csv(file.path(data_dir, "summary", "monthly_global.csv"))
  monthly_area <- read_csv(file.path(data_dir, "summary", "monthly_area.csv"))

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
  stopifnot(abs(sum(monthly_area$fishing_hours) - total_hours) < 0.001)

  cat("B scaffold ready. Global total:",
      formatC(total_hours, format = "f", digits = 4, big.mark = ","), "hours\n")

  # --- T04: Compare estimated fishing hours across the twelve months. ---
  # TODO(member-b): summarise monthly_global by month and design the comparison
  # chart. Write T04_monthly_total.csv and T04_monthly_total.png.

  # --- T05: Compare average daily fishing hours per month. ---
  # TODO(member-b): derive days-in-month and average daily hours, then design the
  # chart. Write T05_daily_average.csv and T05_daily_average.png.

  # --- T06: Identify each FAO area peak month. ---
  # TODO(member-b): join monthly_area with area_names.csv and highlight the peak
  # month per area. Write T06_area_peaks.csv and T06_area_peaks.png.

  invisible(list(shared_dir = shared_dir,
                 output_dir = normalizePath(output_dir),
                 total_hours = total_hours))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 2L) {
    stop("Usage: Rscript analysis_B.R [SHARED_DIR] [OUTPUT_DIR]")
  }
  shared_dir <- if (length(args) >= 1L) args[[1L]] else file.path("..", "..", "DS4073_GFW_2023_Shared")
  output_dir <- if (length(args) == 2L) args[[2L]] else "results"
  invisible(run_b(shared_dir, output_dir))
}