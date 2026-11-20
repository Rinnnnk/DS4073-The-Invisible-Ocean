# Run from this folder: Rscript render_A.R EXTRACTED_SHARED_DIRECTORY [PANDOC_EXECUTABLE]
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || length(args) > 2L) {
  stop("Usage: Rscript render_A.R EXTRACTED_SHARED_DIRECTORY [PANDOC_EXECUTABLE]")
}
pandoc <- if (length(args) == 2L) args[[2L]] else Sys.which("pandoc")
if (!nzchar(pandoc)) {
  dir <- Sys.getenv("RSTUDIO_PANDOC")
  exe <- if (.Platform$OS.type == "windows") "pandoc.exe" else "pandoc"
  if (nzchar(dir)) pandoc <- file.path(dir, exe)
}
if (!nzchar(pandoc) || !file.exists(pandoc)) {
  stop("Pandoc was not found. Pass the path to its executable as the second argument.")
}
knit_env <- new.env()
knit_env$params <- list(shared_dir = normalizePath(args[[1L]], mustWork = TRUE))
markdown <- tempfile("A_T01_T03_", fileext = ".md")
knitr::knit("A_T01_T03.Rmd", markdown, envir = knit_env, quiet = TRUE)
status <- system2(pandoc, c(shQuote(markdown), "--from=markdown", "--to=html5",
                            "--embed-resources", "--standalone", "--css=report.css",
                            "--output=A_T01_T03.html"))
if (status != 0L) stop("Pandoc did not generate the HTML page.")
