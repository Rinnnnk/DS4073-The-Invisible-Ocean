# Report outline and consolidation plan (milestone M03)

Owner: Member D. This file is the agreed outline for `report/Project_Report_Draft.Rmd` and doubles as the hand-off checklist for the consolidated rerun at M06. It fixes what each section must contain, who supplies it, which figure or table it cites, and which numbers every page has to reproduce. Written before the final draft, so it can be circulated to all five members.

## How to use this outline

1. Each member sends their page text from `module_X/DS4073_X_Txx_Txx/Report_and_PPT_notes.md` plus the paths of the figures and tables their text cites. Nobody sends screenshots; only the PNG or CSV the script produced.
2. D pastes the text into the matching subsection below, keeping the numbers exactly as the CSVs report them. Where a number in the text and a number in the CSV disagree, the CSV wins and the author is asked to fix their script or their sentence.
3. D runs the terminology check and the numbers ledger (both later in this file), then knits `Project_Report_Draft.Rmd` to `Project_Report.html` **from the repository root** so every relative path resolves.
4. The group leader and D assemble the contribution table and send it to all five members for a signed check before submission.

## Section plan

| # | Section | Owner of the text | Length | Must contain |
|---|---|---|---|---|
| 1 | Introduction | D | 1 page | Why "invisible ocean": most fishing is not directly observed, so activity is inferred from AIS. The five guiding questions (where, when, which gear, which flag, where hotspots concentrate). The measure defined once here: AIS-estimated **apparent fishing hours**, not catch and not vessel count. |
| 2 | Dataset description | D | 1 page | Unit of observation (month x 0.1 degree cell x flag x gear), the 14,560,171 detail rows, the 111,712,128.6941-hour total, the shared summary tables, and the licence. |
| 3 | Data preprocessing | D | 1 page | `grid_id` from cell lower-left corner; FAO area by grid centre with unmatched and ambiguous centres kept (2,025,905 of 2,040,786 observed cells, 97.9053%, matched exactly one polygon); `flag_group` pooling; `geartype == "fishing"` kept as "Unspecified fishing"; per-module reconciliation. Cite `DS4073_GFW_2023_Shared/qa/`. |
| 4 | Task abstraction | D | 1 page, one table | T01-T15 with question, data, and encoding. Rows for A, C, D are settled; B and E confirm their encodings before this table freezes. |
| 5 | Visualization design principles | D | 1 page | One sequential ramp for hours, one fixed categorical palette for gear and flag roles, bars from a zero baseline, one shared colour range per map panel, every percentage naming its denominator, unknown and unmatched groups always visible or explicitly excluded. Add the consistency table from "Terminology" below. |
| 6 | Results and discussion | A, B, C, D, E (one subsection each) | 1-1.5 pages each | One subsection per page of the dashboard, in A-E order. Each opens with the question, states the measure and denominator, shows the figure, and closes with one take-away sentence. Every number appears in that module's `results/tables/`. |
| 7 | Cross-page synthesis | D | 1 page | The one story the five pages tell together: activity is spatially top-heavy and flag-concentrated, trawling dominates the gear mix, and the largest flag and the largest area are the same part of the ocean. See "Synthesis claims to verify" below. |
| 8 | Limitations | D | half page | AIS coverage and reception gaps; flag and gear uncertainty; unspecified gear; one year only; cell area varies with latitude; no catch or biomass inference. |
| 9 | Appendix | D | 1-2 pages | Data dictionary fields used, the reconciliation table (module, target, produced total, difference), per-module run commands, repository layout. |
| 10 | Team contribution | D + leader | 1 page | Name_StudentID, responsibility, self and peer score on the 30/60/90/100 scale required by the course. Circulated for signature. |

## Figures and tables to cite

Every claim in section 6 links to a named artefact. These names are fixed now so the prose can reference them before the final knit.

| Label | File | Section |
|---|---|---|
| fig-A1, fig-A2, fig-A3 | `module_A/.../results/figures/T01_*.png` ... `T03_*.png` | 6.1 |
| fig-B1, fig-B2, fig-B3 | `module_B/.../results/figures/T04_*.png` ... `T06_*.png` | 6.2 |
| fig-C1, fig-C2, fig-C3 | `module_C/.../results/figures/T07_gear_ranking.png`, `T08_monthly_gear_mix.png`, `T09_gear_maps.png` | 6.3 |
| fig-D1, fig-D2, fig-D3 | `module_D/.../results/figures/T10_flag_ranking.png`, `T11_flag_area.png`, `T12_top3_flags_by_area.png` | 6.4 |
| fig-E1, fig-E2, fig-E3 | `module_E/.../results/figures/T13_*.png` ... `T15_*.png` | 6.5 |
| tab-rec | each module's `results/tables/*_reconciliation.csv` | 3, 9 |

## Numbers ledger

These are the values already reconciled against the shared tables. A sentence that contradicts one of them is a bug, not a difference of opinion. A, C and D are filled in; B and E add their rows before the draft freezes.

| Quantity | Value | Source |
|---|---|---|
| Global apparent fishing hours, 2023 | 111,712,128.6941 | `annual_flag.csv`, `annual_flag_area.csv` |
| Detail rows | 14,560,171 | shared detail files |
| Observed 0.1 degree cells | 2,040,786 (1,193,301 with positive hours) | module A |
| Largest single cell | 119.35 E, 35.05 N: 316,398.92 hours | module A |
| Largest FAO area | Northwest Pacific (61), 68.29 million hours, 61.13% | module A |
| Area not matched to any polygon | 2,340,045 hours, 2.095% | module A, module D |
| Top 1% of cells | 65.98% of all hours | module A |
| Largest gear | Trawlers, 59.37 million hours, 53.15% | module C |
| Unspecified gear | 19.83 million hours, 17.75% | module C |
| Trawler share range | 39.12% (May) to 58.22% (February) | module C |
| Largest flag | CHN, 52,509,581 hours, 47.00% | module D |
| Unknown flag hours | 10,030,470 hours, 8.98% (UNKNOWN plus UNK_UNRESOLVED) | module D |
| Flags reaching 80% / 90% | 11 / 21 of 220 | module D |
| Median area top-three flag share | 70.56% (range 45.6% Northeast Atlantic to 100% Arctic Sea) | module D |
| Flag groups / flag-area rows | 220 / 1,014 | module D |

## Terminology and consistency

Use these forms everywhere, in text, captions, and slide notes.

- **apparent fishing hours** — never "effort", "catch", "landings", "fishing pressure" or "vessels". The unit is hours.
- **flag group** — the analysis label (`flag_group`). First use: "flag group (the flag recorded in the GFW vessel record)". Never "nationality".
- **unspecified fishing** — the pooled `geartype == "fishing"` class, always distinguished from named gears.
- **FAO major area** — the 19 named areas; call the residual **unmatched grid centres**, not "unknown area".
- **unknown flags** — `UNKNOWN` plus `UNK_UNRESOLVED`; say "unknown flag hours", never "unknown fleet".
- Percentages: always state the denominator in the same sentence (global total, the row's own total, or the area total).
- Round hours to whole numbers in prose above one million, keep two decimals in tables, and keep the exact target 111,712,128.6941 wherever reconciliation is discussed.

## Synthesis claims to verify before the draft freezes

Each of these crosses two modules, so no single author owns it. D checks each one against both source tables before writing section 7.

1. The largest area and the largest flag are the same place: Northwest Pacific holds 61.13% of hours (A) and 91% of China's hours (D), so China's 47.00% share is mostly one region. Verify that the implied regional total is consistent: 0.47 x 0.91 is about 42.8% of global hours for China inside the Northwest Pacific, against 61.13% for the area.
2. Gear and flag concentration are independent findings, not the same claim: trawlers at 53.15% (C) and China at 47.00% (D) both describe composition but of different dimensions, so the report must not imply "China trawls" without a flag-by-gear table, which no page produces.
3. Concentration is high at every scale but not equally: 65.98% of hours sit in the top 1% of cells (A), 11 flags hold 80% (D), and three flags hold a median 70.56% of an area (D). State the denominator each time.
4. Unknown and unmatched groups shrink every one of these claims: 8.98% of hours have an unknown flag and 2.095% have no FAO area. If B's or E's numbers exclude either group, the synthesis must say so.

## Milestones

- **M03 (this outline):** circulate, collect agreement on section ownership and the numbers ledger.
- **M04-M05:** A, B, C, E send text and figure paths; D fills sections 1-5 and 7-9 in parallel.
- **M06 (consolidated rerun):** D re-runs all five `analysis_*.R` scripts from a clean results directory, re-knits the report and the dashboard, and confirms every ledger number still matches. Anything that moved is either a fixed bug or a new error, and both are reported to the group.
- **Before submission:** contribution table signed by all five members; `[Your name / student ID]` replaced on every slide; repository packaged as `Group_x.zip`.
