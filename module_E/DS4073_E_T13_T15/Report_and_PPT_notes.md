# E. Hotspot synthesis of apparent fishing activity

**Data and task abstraction.** TODO(member-e): describe the hotspot abstraction of
the 2023 Global Fishing Watch shared data. Hotspots are grid cells with the largest
summed `fishing_hours`. The measure is hours of apparent fishing activity, not catch
or vessel counts. The module reconciles to **111,712,128.6941 hours**.

## T13 - Which grid cells are the strongest hotspots?

**Calculation and design.** TODO(member-e): describe how monthly grid tables are
summed by `grid_id`, how cells are ranked, and how the hotspot map encodes hours.
Mention that cell area varies with latitude.

**Result.** TODO(member-e): report the leading hotspot cells with coordinates and
hours.

## T14 - Which flags dominate the hotspot cells?

**Calculation and design.** TODO(member-e): describe how the detail table is filtered
by the hotspot `grid_id` set and how `flag_group` is aggregated.

**Result.** TODO(member-e): report the leading flags inside the hotspot cells.

## T15 - How does the hotspot gear mix differ from the global mix?

**Calculation and design.** TODO(member-e): describe the hotspot gear aggregation and
how it is compared with the global annual gear mix. Keep `fishing` labelled as
"Unspecified fishing".

**Result.** TODO(member-e): report the main differences in gear composition.

## Interpretation and limits

Hotspots are cells with high recorded apparent fishing hours, not proof of the most
fish. AIS coverage, flag classification, and gear classification vary by region. A
high `grid_id` ranking can reflect a single large cell rather than a broad region.
TODO(member-e): add any data-specific caveats.

## Slide sequence and speaking notes

| Slide | Main point | What to explain |
|---|---|---|
| T13 | TODO | TODO |
| T14 | TODO | TODO |
| T15 | TODO | TODO |

Replace `[Speaker Name / Student ID]` on each slide before submission.