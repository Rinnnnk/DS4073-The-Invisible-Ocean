# Member B - Monthly variation (T04-T06)

This folder is the module B scaffold for *The Invisible Ocean*. It is intentionally
minimal: it loads the shared 2023 summary tables, verifies the global total, and
leaves clean placeholders for the three assigned visual tasks. The final charts are
**not** implemented yet.

## Layout

```
DS4073_B_T04_T06/
|-- analysis_B.R          # Scaffold: parse args, load data, reconcile, TODO
|-- B_T04_T06.Rmd         # R Markdown page skeleton for T04-T06
|-- README.md
|-- Report_and_PPT_notes.md
`-- results/
    |-- tables/.gitkeep
    `-- figures/.gitkeep
```

## Tasks

| Task | Question (placeholder) |
|---|---|
| T04 | How do estimated fishing hours vary across the twelve months of 2023? |
| T05 | How does the average daily fishing effort compare between months? |
| T06 | Which month is the peak for each FAO major marine area? |

## Reproduce

Place this directory beside `DS4073_GFW_2023_Shared` (as in the repository layout)
and run from inside this folder:

```sh
Rscript analysis_B.R ../../DS4073_GFW_2023_Shared results
```

With no arguments the script defaults to `../../DS4073_GFW_2023_Shared` and writes
to `results/`. The script uses base R only.

## Reconciliation

The scaffold stops with an error unless the twelve monthly rows sum to
**111,712,128.6941** hours (tolerance `0.001`) and the area table matches the same
total. Do not remove these checks; the whole group relies on the shared total.