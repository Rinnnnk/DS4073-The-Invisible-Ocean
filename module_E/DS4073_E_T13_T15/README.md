# Member E - Hotspot synthesis (T13-T15)

This folder is the module E scaffold for *The Invisible Ocean*. It checks that the
monthly grid and detail files exist, verifies the global total, and leaves clean
placeholders for the three assigned visual tasks. The final charts are **not**
implemented yet.

## Layout

```
DS4073_E_T13_T15/
|-- analysis_E.R          # Scaffold: parse args, load data, reconcile, TODO
|-- E_T13_T15.Rmd         # R Markdown page skeleton for T13-T15
|-- README.md
|-- Report_and_PPT_notes.md
`-- results/
    |-- tables/.gitkeep
    `-- figures/.gitkeep
```

## Tasks

| Task | Question (placeholder) |
|---|---|
| T13 | Which grid cells are the strongest fishing hotspots? |
| T14 | Which flags dominate the hotspot cells? |
| T15 | How does the gear mix in hotspots differ from the global mix? |

## Reproduce

Place this directory beside `DS4073_GFW_2023_Shared` (as in the repository layout)
and run from inside this folder:

```sh
Rscript analysis_E.R ../../DS4073_GFW_2023_Shared results
```

With no arguments the script defaults to `../../DS4073_GFW_2023_Shared` and writes
to `results/`. The script uses base R only. The hotspot workflow reads
`data/monthly_grid/2023-MM.rds` and `data/detail/2023-MM.rds` month by month to limit
memory, so keep those files present in the shared package.

## Reconciliation

The scaffold stops with an error unless the twelve monthly rows sum to
**111,712,128.6941** hours (tolerance `0.001`) and all monthly grid and detail files
exist. Never sum `mmsi_present` to claim unique vessels; hotspot composition is about
`fishing_hours` only.