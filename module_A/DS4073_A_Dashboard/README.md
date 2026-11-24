# A 页 Dashboard

打开 A_Dashboard.html 即可离线查看。A 页有三个任务，每个任务一行、两张图。点击静态图可放大。T02 散点可悬停和缩放，T03 曲线可悬停并在全范围与前 10% 间切换。

## 填写姓名和学号

在 A_Dashboard.Rmd 顶部 params 里把 student_name 与 student_id 改为本人信息，再在 RStudio 中 Knit。学号建议保留引号，以便保留前导零。本地输出已写入当前 Rmd 中的署名。

## 复跑和合并

1. 把 DS4073_GFW_2023_Shared.zip 放在本目录的旁边。也可以在同一级放已经解压的 DS4073_GFW_2023_Shared 文件夹。Knit 时会按需从 ZIP 读入四个文件。
2. R 中安装 flexdashboard、rmarkdown、knitr、htmltools、data.table、ggplot2、scales、sf，并使用带 Pandoc 的 RStudio。安装 plotly 可以生成可交互图，缺少该包时会使用静态图。
3. 在 RStudio 打开 A_Dashboard.Rmd，点击 Knit，或在本目录运行 rmarkdown::render("A_Dashboard.Rmd")。
4. 整合全组 Dashboard 时，在总 Rmd 中保留本页一级标题 A. Spatial distribution 及其下的三行与图卡。把 A 页的 setup 代码并入总 setup，统一设置 shared_dir 和本页署名。复制两个 R 文件、assets、dashboard.css 和 zoom.js，或将样式与脚本并入总项目。

## Windows 路径报错

如果 Console 的 Rmd 路径显示为 D:/CST/??/...，Knit 收到的文件路径已经出现乱码。将 Dashboard 文件夹和旁边的共享 ZIP 一起复制到纯英文路径，再从新位置打开 Rmd 和 Knit。启动错误与数据缺失错误应分别排查。

## 补充图的数据口径

- T01 局部地图使用和全球图相同的 0.1° 网格及颜色尺度。局部范围是 105°E 至 145°E、12°N 至 48°N。
- T02 散点只比较 19 个匹配的 FAO 海区。活跃网格是全年捕鱼时长大于零的网格。散点仅比较两个汇总指标。
- T03 分段图使用累计占比之差。按排名依次分成前 1%、接下来 4%、接下来 5% 和其余 90%，各组时长占比合计 100%。

results/figures 内有六张 PNG，可用于 PPT。results/tables 保存辅助图数据和原三项任务对账结果。原始数据和 FAO 匹配口径见组内共享数据包。
