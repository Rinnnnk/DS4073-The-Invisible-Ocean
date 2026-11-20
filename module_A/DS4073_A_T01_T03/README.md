# A 部分交付说明

直接打开 `A_T01_T03.html` 查看三项分析。三张图可从 `results/figures/` 插入 PPT 或 Dashboard，`results/tables/` 保存对账和分析数值。`Report_and_PPT_notes.md` 提供英文报告段落与三张 PPT 的讲解要点。

## 在 R 中复跑

把此包和 `DS4073_GFW_2023_Shared` 解压到同一父目录。在本目录运行以下命令。需要 `data.table`、`ggplot2`、`scales` 和 `sf`。

```sh
Rscript analysis_A.R ../DS4073_GFW_2023_Shared
```

要重做 HTML，使用 RStudio 的 Knit 或运行：

```r
rmarkdown::render("A_T01_T03.Rmd",
                  params = list(shared_dir = "../DS4073_GFW_2023_Shared"))
```

也可以运行 Rscript render_A.R ../DS4073_GFW_2023_Shared，并在需要时提供 Pandoc 可执行文件路径作为第二个参数。生成 HTML 需要 knitr 和 Pandoc。整合 Dashboard 时可以导入三张图，也可以在 R 中加载 `analysis_A.R` 并复用图表函数。CSV 的占比列为 0 到 1。

数据使用 [GFW 2023 月度数据 v3.0](https://doi.org/10.5281/zenodo.14982712) 和共享版中的 [FAO 海洋渔区](https://www.fao.org/cwp-on-fishery-statistics/handbook/general-concepts/main-water-areas) 映射。[Natural Earth 1:110m 陆地底图](https://www.naturalearthdata.com/downloads/110m-physical-vectors/110m-land/) 已放在 `assets/` 中。
