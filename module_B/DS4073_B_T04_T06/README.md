# The Invisible Ocean — B: Monthly Change

Open `B_T04_T06.html` to view all three tasks. T06 includes an interactive Plotly comparison, a static heatmap, and a collapsible area value table. The HTML is self-contained. Figures (PNG and PDF) and corresponding audit tables are in `results/`. See `Report_and_PPT_notes.md` for slide text and speaking notes.

## Rebuild

Unzip `DS4073_GFW_2023_Shared.zip` into a separate folder. R packages: data.table, ggplot2, scales, knitr, rmarkdown, htmltools and plotly. Rendering needs Pandoc (available in RStudio). The analysis reads three small CSV files from the shared directory: `data/summary/monthly_global.csv`, `data/summary/monthly_area.csv`, and `data/area_names.csv`.

```sh
Rscript analysis_B.R "../../DS4073_GFW_2023_Shared" results
Rscript render_B.R "../../DS4073_GFW_2023_Shared"
```

Pass a different path as needed. The render command reruns the analysis and embeds the static charts and Plotly widget. The self-contained HTML can be opened locally without internet access.

## Integrating B

In the group Rmd, initialize B in a separate environment to render its named plots and the Plotly widget. Use `T06_global_vs_outside_northwest.png` as the print or slide fallback for the global comparison. For the first dashboard prototype, reuse B's shared-directory parameter and give each person's module its own environment and output directory. B only covers its three tasks.

```r
b_code <- new.env(parent = globalenv())
sys.source(file.path("..", "module_B", "DS4073_B_T04_T06", "analysis_B.R"), envir = b_code)
sys.source(file.path("..", "module_B", "DS4073_B_T04_T06", "interactive_B.R"), envir = b_code)
b <- b_code$run_b(params$shared_root, "../module_B/DS4073_B_T04_T06/results")
print(b$plots$T04)
print(b$plots$T05)
print(b$plots$T06)
# Return this widget as the last expression in a separate Rmd chunk.
b_code$build_interactive_b(b)
```

The month rankings use actual calendar days. The heatmap displays each month's share of the recorded annual hours for that area. It separates missing area-months and marks every tied peak for areas with all 12 months. The series outside the Northwest Pacific equals global hours minus FAO area 61. It retains unmatched grid centres. The heatmap covers 19 official FAO areas. The Plotly area menu compares only the 17 areas with records in all 12 months. All time comparisons refer to 2023.
