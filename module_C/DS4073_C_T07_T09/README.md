# Member C — Gear type (T07–T09)

This package is the C module for *The Invisible Ocean*, using the 2023 Global Fishing Watch v3.0 shared dataset. It contains three R-generated figures, tables, an HTML page, an R Markdown source, report text, and three task slides. Replace `[Your name / student ID]` on each slide before submission.

## Reproduce

Place this directory beside the extracted `DS4073_GFW_2023_Shared` directory. From this directory run:

```sh
Rscript analysis_C.R ../DS4073_GFW_2023_Shared results
```

The script uses **base R only** and reads the shared CSV summaries plus all twelve `data/detail/2023-MM.rds` files. It regenerates all figures and tables. `C_T07_T09.html` is a self-contained viewing copy and can be opened directly. `C_T07_T09.Rmd` is the integration source for B's dashboard; knit it after running `analysis_C.R` with `rmarkdown::render()` or use the three PNGs directly.

## Analysis definitions

- **T07:** annual `fishing_hours` by original `geartype`, descending. `fishing` means the gear was not specified. It is shown as “Unspecified fishing,” never merged with a named gear. All original gear categories remain in the CSV.
- **T08:** monthly `fishing_hours` by gear divided by all fishing hours in the same month. The five largest specifically named gears are fixed for all months, with `fishing` separate and all remaining named gears in “Other classified gear.” Every month sums to 100%.
- **T09:** the three highest-hour **named** gears in T07 are `trawlers`, `drifting_longlines`, and `set_gillnets`. The map sums the original 0.1° rows into 1° cells for legibility. Every panel has the same cell size and color thresholds. Blank cells have no positive recorded hours. The maps are for locations and patterns, not effort per square kilometer; geographic cell area varies with latitude.

The source indicator is apparent fishing activity estimated from AIS, in hours. It is not fish catch, vessel count, or a complete census of fishing. Do not add `mmsi_present` across cells or months to claim unique vessels.

## Checks

`results/tables/C_detail_reconciliation.csv` checks every monthly detail file against the shared monthly summary. `T09_map_reconciliation.csv` checks each mapped gear against T07. The R script stops if these checks, the global total, 12-month coverage, or 100% monthly shares fail. The global total is **111,712,128.6941 hours**, matching A's module.

## Handoff

B can embed `C_T07_T09.html` or include the three PNGs and tables in the group Rmd. D can paste or adapt `Report_and_PPT_notes.md`. E can merge `C_T07_T09_slides.pptx`; the three slides are consecutive and have a name placeholder. Member C's cross-page review remains a follow-up once all five page drafts exist. The review checklist in `Report_and_PPT_notes.md` records what to check.

Source: Global Fishing Watch, fleet monthly CSVs v3.0 for 2023, as prepared in `DS4073_GFW_2023_Shared`. See the shared package's README and data dictionary for version, license, cleaning steps, and limitations.
