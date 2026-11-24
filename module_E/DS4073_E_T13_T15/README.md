# Member E - Hotspot synthesis (T13-T15)

**Author:** Weiye Xu (2430026242)

This package is the E module for *The Invisible Ocean*, using the 2023 Global Fishing Watch v3.0 shared dataset. It produces three high-resolution static figures, eleven reconciled CSV tables (seven core audit tables plus four lightweight pre-aggregated dashboard tables), and a standalone interactive `flexdashboard` HTML (`E_T13_T15.html`).

## Files

| File | Purpose |
|---|---|
| `analysis_E.R` | Main pipeline: T13-T15 with `stopifnot()` reconciliation, static PNGs, and pre-aggregated dashboard CSVs |
| `E_T13_T15.Rmd` | Interactive 5-row, 6-chart `flexdashboard` page (`Weiye Xu | 2430026242`) |
| `render_E.R` | Sets `RSTUDIO_PANDOC` automatically and renders `E_T13_T15.html` via `rmarkdown::render()` |
| `report.css` | Shared report styling (matches Module A) |
| `Report_and_PPT_notes.md` | Academic write-up, dashboard architecture notes, and speaking notes |
| `assets/ne_110m_land.zip` | Natural Earth 110m land (self-contained copy) |

## Output filenames

Figures (`results/figures/`): `T13_persistence_map.png`, `T14_hotspot_composition.png`, `T15_monthly_comparison.png`.

Tables (`results/tables/`):
- Core audit tables: `T13_hotspot_persistence.csv`, `T13_spot_checks.csv`, `T14_hotspot_flag_gear.csv`, `T14_hotspot_reconciliation.csv`, `T15_hotspot_monthly_share.csv`, `T15_reconciliation.csv`, `E_reconciliation.csv`.
- Dashboard pre-aggregated tables: `T13_leaflet_cells.csv` (1,384 cells with `persistence_months >= 7`), `T13_tier_summary.csv`, `T14_macro_structure.csv`, `T15_monthly_deviation.csv`.

## Dashboard Architecture (5 Rows, 6 Charts)

- **Row 1 (KPI Summary Bar):** Author `valueBox`, 224 persistent cells `valueBox`, Hotspot A global share `gauge` (27.5%), and opposing seasonal peaks `valueBox` (`Oct vs Jul`).
- **Row 2 (Task 13):** `leaflet` interactive persistence map (Esri WorldGrayCanvas, bounding boxes, popups) + static 2.04M-cell global map tab (`Chart 1`); `plotly` grouped bar chart comparing cell share vs fishing-hour share across 5 tiers (`Chart 2`).
- **Row 3 (Task 14):** `plotly::subplot` faceted Top 8 `Flag x Gear` horizontal bars (`Chart 3`); tabbed `plotly` 100% stacked Gear Diversity & Flag Concentration bars (`Chart 4`).
- **Row 4 (Task 15):** `dygraphs` normalized monthly trajectories vs dashed global benchmark (`Chart 5`); `plotly` diverging monthly deviation bars in percentage points (`Chart 6`).
- **Row 5 (Explorer & Audit):** Searchable `DT::datatable()` of all 224 year-round persistent cells + `knitr::kable()` reconciliation and spot-check tables.

## Reproduce

Place this directory beside the extracted `DS4073_GFW_2023_Shared` directory. From this directory run:

```sh
Rscript analysis_E.R ../../DS4073_GFW_2023_Shared results
```

Required R packages: `data.table`, `ggplot2`, `scales`, `sf` (for `analysis_E.R`) and `flexdashboard`, `plotly`, `leaflet`, `dygraphs`, `DT`, `xts`, `htmltools`, `rmarkdown`, `knitr` (for `E_T13_T15.Rmd`). To render the standalone interactive HTML:

```sh
Rscript render_E.R ../../DS4073_GFW_2023_Shared
```

## Analysis definitions

- **T13:** monthly top-1% threshold (`quantile(probs = 0.99, type = 7)`) among active cells (`fishing_hours > 0`); a cell is high when `hours >= cutoff` (ties included). Persistence is the number of high months (1-12). Unobserved and zero months are non-hits.
- **T14:** two grid-centre bounding boxes - A: 118-126 E, 28-38 N; B: -75..-50 E, 40-55 N. Aggregates `flag_group x geartype`; top 8 plus `Other combinations`; `fishing` is labeled `Unspecified fishing`.
- **T15:** each series is normalised to 100%; the global benchmark is `monthly_global / 111,712,128.6941`.

## Checks

`analysis_E.R` stops unless: the global total is 111,712,128.6941 hours; all 12 months are present; monthly_grid totals match monthly_global; detail totals match monthly_grid totals in each hotspot; each T15 series sums to 1.0; and spot-check hit flags reconcile with persistence counts. `E_reconciliation.csv` records these checks.

## Handoff

The dashboard Module E page should embed `T13_persistence_map.png`, `T14_hotspot_composition.png`, and `T15_monthly_comparison.png`. Note: the dashboard placeholders currently reference older filenames (`T13_hotspot_map.png`, `T14_hotspot_flags.png`, `T15_hotspot_gears.png`) and must be updated at integration time. The slide deck will be generated in a later step.

Source: Global Fishing Watch, fleet monthly CSVs v3.0 for 2023, as prepared in `DS4073_GFW_2023_Shared`.