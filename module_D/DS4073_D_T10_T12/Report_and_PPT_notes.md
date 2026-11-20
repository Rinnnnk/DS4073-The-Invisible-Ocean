# D. Flag distribution of apparent fishing activity

**Data and task abstraction.** TODO(member-d): describe the flag abstraction of the
2023 Global Fishing Watch shared data. The measure is `fishing_hours` in hours.
`flag_group` is the analysis flag label; `UNKNOWN` and `UNK_UNRESOLVED` are kept
visible. The module reconciles to **111,712,128.6941 hours**.

## T10 - Which vessel flags dominate?

**Calculation and design.** TODO(member-d): describe the annual ranking and the chart
encoding (for example a horizontal bar with a zero baseline).

**Result.** TODO(member-d): report the leading flags and their shares.

## T11 - How is flag activity distributed by area?

**Calculation and design.** TODO(member-d): describe the join to `area_names.csv` and
how the area-by-flag distribution is shown.

**Result.** TODO(member-d): summarise the main flag-area patterns.

## T12 - What share do the top three known flags contribute per area?

**Calculation and design.** TODO(member-d): describe how the top three known flags per
area are computed, why `UNKNOWN` and `UNK_UNRESOLVED` are excluded from the ranking,
and how the denominator is kept.

**Result.** TODO(member-d): report the contribution of the top three flags per area.

## Interpretation and limits

Flag classification reflects GFW flag assignment and can be uncertain; unknown flags
are common. Share comparisons describe recorded flags, not the true flag of the
vessel. Never sum `mmsi_present` across cells or months to claim unique vessels.
TODO(member-d): add any data-specific caveats.

## Slide sequence and speaking notes

| Slide | Main point | What to explain |
|---|---|---|
| T10 | TODO | TODO |
| T11 | TODO | TODO |
| T12 | TODO | TODO |

Replace `[Speaker Name / Student ID]` on each slide before submission.