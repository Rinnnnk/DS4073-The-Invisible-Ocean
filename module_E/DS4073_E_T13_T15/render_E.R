# Run from this folder: Rscript render_E.R [SHARED_DIR] [PANDOC_DIR_OR_EXE]
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 2L) {
  stop('Usage: Rscript render_E.R [SHARED_DIR] [PANDOC_DIR_OR_EXE]')
}

shared_dir <- if (length(args) >= 1L) args[[1L]] else file.path('..', '..', 'DS4073_GFW_2023_Shared')
shared_dir <- normalizePath(shared_dir, mustWork = TRUE)

locate_pandoc_dir <- function(arg_path = NULL) {
  if (!is.null(arg_path) && nzchar(arg_path)) {
    p <- normalizePath(arg_path, mustWork = TRUE)
    if (file.info(p)$isdir) return(p)
    return(dirname(p))
  }
  env_dir <- Sys.getenv('RSTUDIO_PANDOC')
  if (nzchar(env_dir) && dir.exists(env_dir)) return(env_dir)
  rstudio_dir <- file.path('C:', 'Program Files', 'RStudio', 'resources', 'app',
                           'bin', 'quarto', 'bin', 'tools')
  if (dir.exists(rstudio_dir)) return(rstudio_dir)
  which_pandoc <- Sys.which('pandoc')
  if (nzchar(which_pandoc)) return(dirname(which_pandoc))
  stop('Pandoc was not found. Pass its directory or executable as the second argument.')
}

pandoc_dir <- locate_pandoc_dir(if (length(args) == 2L) args[[2L]] else NULL)
Sys.setenv(RSTUDIO_PANDOC = pandoc_dir)

required_tables <- c(
  'results/tables/T13_leaflet_cells.csv',
  'results/tables/T13_tier_summary.csv',
  'results/tables/T14_hotspot_flag_gear.csv',
  'results/tables/T14_macro_structure.csv',
  'results/tables/T14_hotspot_reconciliation.csv',
  'results/tables/T15_hotspot_monthly_share.csv',
  'results/tables/T15_monthly_deviation.csv',
  'results/tables/T13_spot_checks.csv',
  'results/tables/E_reconciliation.csv'
)

if (!all(file.exists(required_tables))) {
  source('analysis_E.R', local = TRUE)
  run_e(shared_dir = shared_dir, output_dir = 'results')
}

rmarkdown::render(
  input = 'E_T13_T15.Rmd',
  output_file = 'E_T13_T15.html',
  params = list(shared_dir = shared_dir),
  envir = new.env(parent = globalenv()),
  quiet = FALSE
)
