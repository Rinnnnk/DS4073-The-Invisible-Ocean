# Member D — Vessel flag (T10–T12)

This package is the D module for *The Invisible Ocean*, using the 2023 Global Fishing Watch v3.0 shared dataset. It contains three R-generated figures, four audit tables, an HTML page, an R Markdown source, report and speaking text, and three task slides. Replace `[Your name / student ID]` on each slide before submission.

## Reproduce

Place this directory beside the extracted `DS4073_GFW_2023_Shared` directory. From this directory run:

```sh
Rscript analysis_D.R ../../DS4073_GFW_2023_Shared results
```

The script reads only the shared summary tables (`annual_flag.csv`, `annual_flag_area.csv`, `area_names.csv`), never the 14.6 million-row detail files, so it runs in seconds. It needs **`ggplot2`** in addition to base R; no `data.table` or `sf` is required. `D_T10_T12.html` is a self-contained viewing copy and can be opened directly. `D_T10_T12.Rmd` is the integration source for the dashboard; knit it with `rmarkdown::render()` or include the three PNGs directly. `make_page_slides.py` rebuilds `D_T10_T12_slides.pptx` from the same PNGs (python-pptx required).

## Analysis definitions

- **T10:** annual `fishing_hours` by `flag_group`, ranked descending over all 220 groups. The chart shows the top 25 plus one pooled "Other 195 flags" bar; the CSV keeps every row. The denominator is the global total, so shares sum to 100%.
- **T11:** each flag's hours in each FAO area divided by **that flag's own annual total** — a row normalization, so every row sums to 100%. Column normalization would answer T12 instead. Grid centres outside every FAO polygon are kept as a separate column.
- **T12:** per area, the three largest **known** flags (excluding `UNKNOWN` and `UNK_UNRESOLVED` from the ranking) divided by the **area total including unknown-flag hours**. The unknown hours stay in the denominator so an unlabelled area cannot look dominated. `n_known_flags` records how many flags were available to rank; the Arctic Sea has only three.

`flag_group` is the analysis label: `UNKNOWN` pools all raw `UNKNOWN-*` flags and `UNK_UNRESOLVED` is the unresolved `UNK`. Both are kept visible — together they are 8.98% of all hours. The source indicator is apparent fishing activity estimated from AIS, in hours. It is not fish catch, vessel count, or a complete census of fishing, and flag labels are GFW flag groups, not verified vessel nationality. Do not add `mmsi_present` across cells or months to claim unique vessels.

## Checks

`results/tables/D_reconciliation.csv` records the global total, the target, the absolute difference, row counts, the number of areas actually present, and the largest deviation between a flag's per-area sum and its annual total. The R script stops unless both summary tables sum to **111,712,128.6941 hours** (tolerance `0.001`), every flag's per-area rows add back to its annual total, and every row-normalized share sums to 1.

## Handoff

B can embed `D_T10_T12.html` or include the three PNGs and tables in the group Rmd; the dashboard's fourth page already points at the PNGs. E can merge `D_T10_T12_slides.pptx`; the three slides are consecutive and carry a name placeholder. D also consolidates the report: `Report_and_PPT_notes.md` ends with the cross-page review checklist that the group report must pass, and the report outline lives in `report/`.

Source: Global Fishing Watch, fleet monthly CSVs v3.0 for 2023, as prepared in `DS4073_GFW_2023_Shared`. See the shared package's README and data dictionary for version, license, cleaning steps, and limitations.
