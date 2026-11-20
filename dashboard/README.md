# Integrated dashboard

`index.Rmd` is a five-page `flexdashboard` skeleton that brings modules A-E into one
page. It currently embeds the finished module A and module C figures as working
examples; the module B, D, and E pages contain clean `TODO` placeholders.

## Pages

| Page | Module | Tasks | Status |
|---|---|---|---|
| 1 | A - Spatial distribution | T01-T03 | Figures linked (done) |
| 2 | B - Monthly variation | T04-T06 | Placeholder |
| 3 | C - Gear classification | T07-T09 | Figures linked (done) |
| 4 | D - Flag distribution | T10-T12 | Placeholder |
| 5 | E - Hotspot synthesis | T13-T15 | Placeholder |

## Render

Run each module first so its figures exist, then from this folder:

```r
rmarkdown::render("index.Rmd")
```

or

```sh
Rscript -e "rmarkdown::render(\"index.Rmd\")"
```

`flexdashboard` must be installed. Figures are referenced with relative paths such as
`../module_A/DS4073_A_T01_T03/results/figures/...`; keep the repository layout intact
so these paths resolve.

## Handoff

Replace each `TODO` block with a `knitr::include_graphics()` call once the owning
module has produced its figure. Keep the page order A-E so the narrative flows from
"where" (A) to "when" (B), "which gear" (C), "which flag" (D), and "hotspots" (E).