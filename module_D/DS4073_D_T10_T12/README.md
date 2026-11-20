# Member D - Flag distribution (T10-T12)

This folder is the module D scaffold for *The Invisible Ocean*. It loads the shared
annual flag tables, verifies the global total, and leaves clean placeholders for the
three assigned visual tasks. The final charts are **not** implemented yet.

## Layout

```
DS4073_D_T10_T12/
|-- analysis_D.R          # Scaffold: parse args, load data, reconcile, TODO
|-- D_T10_T12.Rmd         # R Markdown page skeleton for T10-T12
|-- README.md
|-- Report_and_PPT_notes.md
`-- results/
    |-- tables/.gitkeep
    `-- figures/.gitkeep
```

## Tasks

| Task | Question (placeholder) |
|---|---|
| T10 | How are estimated fishing hours distributed across vessel flags? |
| T11 | How is flag activity distributed across FAO marine areas? |
| T12 | What share do the top three known flags contribute per area? |

## Reproduce

Place this directory beside `DS4073_GFW_2023_Shared` (as in the repository layout)
and run from inside this folder:

```sh
Rscript analysis_D.R ../../DS4073_GFW_2023_Shared results
```

With no arguments the script defaults to `../../DS4073_GFW_2023_Shared` and writes
to `results/`. The script uses base R only.

## Reconciliation

The scaffold stops with an error unless `annual_flag` and `annual_flag_area` both sum
to **111,712,128.6941** hours (tolerance `0.001`). Keep `UNKNOWN` and
`UNK_UNRESOLVED` in the denominator even when they are excluded from a ranking, and
never sum `mmsi_present` to claim unique vessels.