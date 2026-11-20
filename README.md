# The Invisible Ocean - 2023 Global Fishing Watch Visual Analytics

Group project for **DS4073 Data Visualization**. This repository analyses the 2023
Global Fishing Watch (GFW) apparent fishing effort dataset and turns it into a set
of coordinated visual analytics modules, an integrated dashboard, an academic
report, and a presentation deck.

The project is organised as five analysis modules (A-E), each owned by one team
member and responsible for three visualization tasks (T01-T15 in total). All
modules read a single shared data package so that every number reconciles to the
same global total.

## Global reconciliation target

Every module must reconcile to the same 2023 apparent fishing effort:

- **Total apparent fishing hours:** `111,712,128.6941`
- **Coverage:** twelve months, `2023-01-01` to `2023-12-01`
- **Measure:** `fishing_hours`, AIS-estimated apparent fishing activity in hours.
  It is **not** landed catch and **not** a count of unique vessels.

## Repository layout

```
DS4073-The-Invisible-Ocean/
|-- DS4073_GFW_2023_Shared/   # Shared prepared dataset (read-only input)
|   |-- data/                 # Large tables (not committed)
|   |-- qa/                   # Quality-assurance checks
|   |-- scripts/prepare_gfw.R # Rebuild script for the shared package
|   |-- sources/              # Source shapefiles (not committed)
|   |-- README.md
|   `-- DATA_DICTIONARY.md
|-- module_A/                 # Spatial distribution (T01-T03)
|-- module_B/                 # Monthly variation (T04-T06)
|-- module_C/                 # Gear classification (T07-T09)
|-- module_D/                 # Flag distribution (T10-T12)
|-- module_E/                 # Hotspot synthesis (T13-T15)
|-- dashboard/                # Integrated 5-page flexdashboard
|-- report/                   # Academic report draft
|-- ppt/                      # Master slide deck builder
`-- .gitignore
```

Each module folder contains a self-contained sub-package
(`module_X/DS4073_X_Txx_Txx/`) with its own `analysis_X.R`, `X_Txx_Txx.Rmd`,
`README.md`, `Report_and_PPT_notes.md`, and `results/{tables,figures}/`.

## Local setup

1. Clone the repository.
2. Place the prepared shared data inside `DS4073_GFW_2023_Shared/`:

   ```
   DS4073_GFW_2023_Shared/
   `-- data/
       |-- summary/      # annual_*.csv, monthly_*.csv, monthly_global.csv ...
       |-- detail/       # 2023-01.rds ... 2023-12.rds
       |-- monthly_grid/ # 2023-01.rds ... 2023-12.rds
       |-- area_names.csv
       `-- grid_lookup.rds
   ```

   The `data/` and `sources/` folders are **git-ignored** because they are large.
   They are distributed separately (see the shared package README). To rebuild them
   from the raw GFW download, run `Rscript scripts/prepare_gfw.R`.

3. Run any module from its own sub-directory. The shared path defaults to
   `../../DS4073_GFW_2023_Shared`, for example:

   ```sh
   cd module_B/DS4073_B_T04_T06
   Rscript analysis_B.R ../../DS4073_GFW_2023_Shared results
   ```

## R environment

Tested with R 4.3+ on Windows. Required packages:

| Package | Used for |
|---|---|
| `data.table` | Fast loading and aggregation of the large detail tables |
| `ggplot2` | Static figures in module A |
| `scales` | Axis and percentage formatting |
| `sf` | Reading Natural Earth land polygons for maps |
| `knitr` / `rmarkdown` | Rendering module `.Rmd` pages |
| `flexdashboard` | Integrated dashboard (`dashboard/index.Rmd`) |

Module C and the module B/D/E starter scripts use **base R only**. Python 3 with
`python-pptx` and `Pillow` is required only for slide generation in `ppt/`.

## Git collaboration workflow

- Branch per module: `module-a` ... `module-e`, plus `integration`.
- Do **not** commit `DS4073_GFW_2023_Shared/data/`, `DS4073_GFW_2023_Shared/sources/`,
  `*.zip`, `*.rds`, or `*.RData`; they are already listed in `.gitignore`.
- Keep the shared data directory read-only; each module writes only to its own
  `results/` folder.
- Before merging, confirm the module still reconciles to `111,712,128.6941` hours.
- Open a pull request into `main`, request one reviewer, and squash-merge.

## Data source and licence

Global Fishing Watch v3.0 fleet monthly data for 2023, distributed under CC BY-NC
4.0. Cite Global Fishing Watch in the report and in every figure caption.