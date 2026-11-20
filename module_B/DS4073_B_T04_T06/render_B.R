# Run from anywhere: Rscript path/to/render_B.R PATH_TO_EXTRACTED_SHARED_DIRECTORY
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Usage: Rscript render_B.R PATH_TO_EXTRACTED_SHARED_DIRECTORY")
shared <- normalizePath(args[[1L]], mustWork = TRUE)
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
project_dir <- dirname(normalizePath(script, mustWork = TRUE))
rmarkdown::render(
  input = file.path(project_dir, "B_T04_T06.Rmd"),
  params = list(shared_dir = shared),
  envir = new.env(),
  quiet = TRUE
)
