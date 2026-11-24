# E. Hotspot synthesis of apparent fishing activity

**Data and task abstraction.** The 2023 Global Fishing Watch shared data aggregate AIS-based apparent fishing hours by month, 0.1-degree grid cell, vessel flag, and geartype. The quantitative measure is `fishing_hours` (hours of apparent fishing activity), not landed catch and not a count of unique vessels. In Munzner's attribute typology: month and grid position are **ordered / spatial** attributes; `fishing_hours` is **quantitative**; `flag_group` and `geartype` are **categorical**. The three tasks map to action-target pairs: **T13 Identify** (which cells are persistent vs pulse), **T14 Summarize + Compare** (which flag x gear combinations dominate two hotspots), and **T15 Compare** (hotspot monthly shape vs the global benchmark). Module E is the synthesis view: it combines **space (A)**, **time (B)**, **gear (C)**, and **flag (D)** to reveal structural hotspot typologies.

## T13 - Where did intensity persist?

**Calculation and design.** A cell is active in a month when its `fishing_hours` are positive. For each month, the top-1% threshold is the 99th percentile of that month's active cells (`stats::quantile(..., probs = 0.99, type = 7)`). A cell is high-activity when its hours are **at or above** the cutoff; the `>=` rule includes boundary ties conservatively. A month with no row (unobserved) or with zero hours is not a hit. Persistence is the number of months (1-12) a cell is high-activity.

Visual encoding: **position** (longitude/latitude) carries spatial geometry; **color** (a discrete sequential ramp over tiers 0, 1-3, 4-6, 7-9, 10-12) encodes the ordered month count. Ordered data use an ordered luminance sequence, which respects **expressiveness**. The land polygons (Natural Earth 110m) reuse Module A's gray fill so the five-module suite stays consistent.

**Result.** Only **224 cells** (0.011% of 2,040,786 observed cells) stayed in the top 1% for 10-12 months; 2,029,128 cells never entered the top 1%. The most persistent cell is centred at **119.35 E, 35.05 N** (Northwest Pacific), the same cell Module A reports as the global maximum, with **316,398.92 hours** and 12/12 monthly hits. The tier summary is audited in `T13_hotspot_persistence.csv` and `T13_spot_checks.csv`.

## T14 - What drives two contrasting hotspots?

**Calculation and design.** Two hotspot boxes are fixed by grid-centre bounding boxes, chosen from the T13 persistence results:
- **A - NW Pacific coastal shelf** (118-126 E, 28-38 N): 30,737,250.9962 hours (27.51% of global), 5,325 cells, persistent and trawler-dominated.
- **B - NW Atlantic** (75-50 W, 40-55 N): 843,741.9239 hours (0.76% of global), 17,980 cells, strongly seasonal and more gear-diverse.

For each box, all 12 `detail/2023-MM.rds` files are filtered to the box grid ids and aggregated by `flag_group x geartype`. The top 8 combinations are shown; the remainder is grouped as `Other combinations`. `geartype == fishing` is labeled `Unspecified fishing` and kept in a neutral gray (#8C8C8C), never merged into named gears.

Visual encoding: horizontal **bars** with **length** encoding the share of that hotspot's own annual hours (zero baseline); **color** encodes `geartype` with a fixed mapping across both panels. Because both panels share the same color rule, they support **Qu and Hullman's Same Rule** consistency.

**Result.** A is dominated by **CHN - trawlers** (53.29%); B by **USA - trawlers** (21.26%) and **CAN - trawlers** (19.28%). A has 351 flag x gear combinations but is highly concentrated (CHN 83.4% of flags); B has 47 combinations and a dual-flag structure (CAN 51.7%, USA 45.2%). Reconciliation: detail totals equal monthly-grid totals exactly.

## T15 - Monthly trajectories vs the global benchmark

**Calculation and design.** Each series is normalised by its own annual total so it sums to 100%: global uses `monthly_global.csv / 111,712,128.6941`, and each hotspot uses its own monthly totals from `monthly_grid`. The chart uses a unified 0-20% scale with **position** (month on x, share on y), **line** marks, and **colour/linetype** to separate series: a dashed dark line for the global benchmark and solid amber/blue lines for A/B (colors shared with T14). Peak months are annotated directly to raise the **data-ink ratio**.

**Result.** The global benchmark peaks in **Oct**. Hotspot A also peaks in **Oct** (it drives the global autumn peak), whereas Hotspot B peaks in **Jul** (a boreal-summer pulse). Each series sums to 1.0 exactly (`T15_reconciliation.csv`).

## Design principles and synthesis value

- **Effectiveness vs expressiveness:** ordered month counts use ordered color (T13); categorical gear uses categorical color (T14); time uses position (T15).
- **Graphical integrity:** every bar and share states its denominator; all series start at zero; percentages are shares, not absolute hours.
- **Multiple-views consistency (Qu and Hullman):** T14 and T15 share the same two hotspots and the same accent colors (Same Rule); T13 and T14 use different encodings because they answer different questions (Different Rule).
- **Synthesis:** T13 locates persistence (space x time), T14 attributes the drivers (flag x gear), and T15 explains the temporal rhythm against the global benchmark. Together they turn Modules A-D into a structural typology of hotspots.

## Limitations

AIS reception and GFW activity, flag, and gear classification vary by region. A 0.1-degree cell covers different physical area by latitude; persistence counts angular cells, not area-normalised intensity. Unobserved months are treated as non-hits, which is conservative. The 2023 snapshot cannot establish a longer-term trend.

## Slide sequence and speaking notes

| Slide | Main point | What to explain |
|---|---|---|
| T13 | Only 224 cells persisted 10-12 months. | The top-1% rule, the tie rule, and the discrete tier color ramp. |
| T14 | CHN-trawlers drive A; USA/CAN-trawlers drive B. | Zero-baseline bars, gear color mapping, and gray Unspecified fishing. |
| T15 | Global and A peak Oct; B peaks Jul. | Normalisation to 100%, the dashed benchmark, and shared hotspot colors. |

## Interactive Flexdashboard Architecture (`E_T13_T15.Rmd`)

The standalone `flexdashboard` page (**Weiye Xu | 2430026242**) implements a 5-row, 6-chart interactive layout backed by lightweight pre-aggregated CSVs (`T13_leaflet_cells.csv`, `T13_tier_summary.csv`, `T14_macro_structure.csv`, `T15_monthly_deviation.csv`) and strict Qu & Hullman multi-view color consistency (`#C27D38` Hotspot A, `#4C5B9E` Hotspot B, `#263B47` Global benchmark, `#0E7478` trawlers, `#8C8C8C` Unspecified fishing, `#CBD2D6` Other):

- **Row 1 (`data-height=130`)**: KPI summary bar using `valueBox` and `gauge` (author identity, 224 year-round persistent cells, 27.5% Hotspot A global share, Oct vs Jul opposing seasonal peaks).
- **Row 2 (`data-height=520`)**: `leaflet` interactive persistence map (`persistence_months >= 7`, Esri WorldGrayCanvas tiles, clickable popups, Hotspot A & B bounding boxes) paired with a static 2.04M-cell global map tab (`Chart 1`) and a `plotly` grouped horizontal bar chart comparing cell share vs fishing-hour share across 5 persistence tiers (`Chart 2`).
- **Row 3 (`data-height=520`)**: `plotly::subplot` faceted Top 8 `Flag x Gear` horizontal bars with deduplicated gear legends (`Chart 3`) and a tabbed `plotly` 100% stacked comparison (`Gear Diversity` & `Flag Concentration`, `Chart 4`).
- **Row 4 (`data-height=460`)**: `dygraphs` normalized monthly trajectories with dashed global benchmark (`Chart 5`) and a `plotly` diverging monthly deviation bar chart in percentage points (`Chart 6`).
- **Row 5 (`data-height=450`)**: Searchable `DT::datatable()` explorer for all 224 persistent cells (`10-12` months) plus `knitr::kable()` reconciliation (`111,712,128.6941` hours) and spot-check tables.

Author: **Weiye Xu (2430026242)**.