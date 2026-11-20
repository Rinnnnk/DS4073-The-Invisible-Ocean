# C. Gear classification of apparent fishing activity

**Data and task abstraction.** The 2023 Global Fishing Watch shared data aggregate AIS-based apparent fishing hours by month, 0.1° grid cell, vessel flag, and `geartype`. Our quantitative measure is `fishing_hours`, not landed catch or the number of unique vessels. C addresses three questions: which gear classifications account for most annual hours (T07), how the mix varies by month (T08), and where leading named gears were observed (T09). The 2023 total is **111,712,128.6941 hours**, matching A's global total.

## T07 — Which gears contributed the most hours?

**Calculation and design.** Sum the shared annual gear table's `fishing_hours` by original category and rank descending. Horizontal bar length encodes hours from a common zero baseline. The gray `fishing` bar is relabeled “Unspecified fishing”: GFW has not assigned a more specific gear to these hours. It is part of the overall denominator, not a named gear. Keep all 16 categories in the audit CSV.

**Result.** `trawlers` contributed **59.37 million hours (53.15%)**. The unspecified `fishing` class contributed **19.83 million (17.75%)**. Among named gears, `drifting_longlines` was next at **12.95 million (11.59%)**, followed by `set_gillnets` at **5.66 million (5.06%)**. These are classification totals, not numbers of fish caught.

## T08 — How did the monthly mix change?

**Calculation and design.** Divide each category's monthly hours by the total hours in that **same month**. Use a 100% stacked bar chart: vertical position and color show composition, and all twelve bars share the same 0–100% scale. Keep the five largest named gears from T07 as fixed colors throughout the year. Show unspecified `fishing` separately; merge the remaining named classes into “Other classified gear” through a fixed mapping. The resulting seven categories sum to 100% in every month. A zero-hour month would be marked unavailable rather than divided by zero; none occurs in these data.

**Result.** `trawlers` remained the largest category in each month, but its share fell to **39.12% in May** and rose to **58.22% in February**. The comparison describes **composition**; a higher share does not by itself mean more absolute hours. Inspect the monthly table for exact values and other classes.

## T09 — Where were leading named gears observed?

**Calculation and design.** Select the three largest specifically named gears in the T07 ranking: `trawlers`, `drifting_longlines`, and `set_gillnets`. Exclude `fishing` from this selection because it has no specific gear assignment, while retaining it in T07 and T08. Read all 12 monthly detail files. For each selected gear, sum positive fishing hours from the original 0.1° records into 1° longitude–latitude cells using the same floor-coordinate rule. Draw three aligned world panels with identical 1° cells and identical hour color thresholds. Color is ordered and sequential; blank means no positive recorded hours in that cell. The exported 1° table is the numeric input to the figure.

**Result.** The three maps have visibly different spatial footprints. Trawling is concentrated along several continental margins, with a particularly high 1° cell at **123–124° E, 30–31° N** (about **1.29 million hours**). Drifting longlines are more spread across open-ocean belts; their highest 1° cell is at **80–81° E, 5–6° N** (about **141,497 hours**). Set gillnets form narrower coastal clusters; their highest 1° cell is at **107–108° E, 10–11° N** (about **247,736 hours**). These peak cells were found from the shared detail data and can be checked in `T09_gear_map_1deg.csv`.

**Interpretation and limits.** AIS reception and GFW's activity and gear classification can vary by region. A 1° cell covers different physical area at different latitudes, so colors represent total observed hours per angular cell, not area-normalized intensity. Map blankness does not prove absence of fishing. The 2023 snapshot cannot establish a longer-term trend.

## Slide sequence and speaking notes (about 3 minutes total)

| Slide | Main point | What to explain |
|---|---|---|
| T07 | Trawlers account for 53.15% of observed estimated hours. | Bar length is annual hours. Gray `fishing` is unspecified gear, not a separate technique. |
| T08 | Trawler share varies from 39.12% in May to 58.22% in February. | Every denominator is that month's total; the chart shows proportions, not monthly volume. |
| T09 | Leading named gears have different observed footprints. | Same 1° cells and color thresholds in all panels. Mention AIS coverage and angular cell area. |

On each PowerPoint slide replace `[Your name / student ID]`. R implementation uses `readRDS`, `read.csv`, `aggregate`, `barplot`, and `image`; no add-on package is required for C's script. The HTML can be shown as the demo page.

## Cross-page review checklist for C

The other four pages were not supplied here, so their results cannot yet be signed off. When drafts arrive, compare their global and monthly totals with the shared QA tables, confirm all units say estimated fishing **hours**, check that percentages state their denominator, ensure Unknown and unmatched groups are visible or explicitly excluded, and verify shared filters change both numbers and legends. Record each discrepancy and ask its page author to correct it before B's final rerun.
