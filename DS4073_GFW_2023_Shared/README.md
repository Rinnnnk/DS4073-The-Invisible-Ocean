# The Invisible Ocean 组内共享数据

本包供 DS4073 五位组员使用。解压后可直接用 R 读取数据。2023 年数据按 **月 × 0.1° 网格 × 船旗 × 渔具** 组织。建议每个人使用同一份共享数据，在自己的 R 页面代码里完成分析、图表、PPT 和报告。

全年明细保留 **14,560,171 行**。捕鱼时长合计 **111,712,128.6941 小时**。FAO 匹配覆盖 **2,025,905 / 2,040,786 个观测网格**，覆盖全年估计捕鱼时长的 **97.9053%**。未归入唯一海区的记录保留在各表中，详见 QA。

## 按任务选数据

| 页面 | 文件 | 用途 |
|---|---|---|
| A 空间分布 | `data/summary/annual_grid.rds`、`data/grid_lookup.rds`、`data/summary/annual_area.csv` | 绘制全年网格地图，比较海区总量，计算活跃网格的累计贡献 |
| B 月度变化 | `data/summary/monthly_global.csv`、`data/summary/monthly_area.csv` | 比较每月总量、每日日均及各海区峰值 |
| C 渔具类型 | `data/summary/annual_gear.csv`、`data/summary/monthly_gear.csv`、`data/detail/` | 排名与月度构成用小表，渔具地图逐月从明细聚合 |
| D 船旗分布 | `data/summary/annual_flag.csv`、`data/summary/annual_flag_area.csv` | 船旗排名、海区分布、各海区前三个已知船旗的贡献 |
| E 热点综合 | `data/monthly_grid/`、`data/summary/monthly_global.csv`、`data/detail/` | 用月度网格表识别热点，再按固定 grid_id 从明细筛选热点，比较船旗和渔具组成 |
| 通用 | `data/summary/monthly_area_gear_flag.rds`、`data/area_names.csv` | 跨月份、海区、渔具与船旗分组，以及渔区代码和名称 |

## 读表示例

在解压目录打开 R 或 RStudio。读取 CSV 时显式保留字符代码，避免混用数字代码与未匹配标签。

```r
monthly <- read.csv("data/summary/monthly_global.csv")
monthly$date <- as.Date(monthly$date)

jan <- as.data.frame(readRDS("data/detail/2023-01.rds"))
jan$date <- as.Date(jan$date)

grid <- as.data.frame(readRDS("data/grid_lookup.rds"))
annual_grid <- as.data.frame(readRDS("data/summary/annual_grid.rds"))
annual_map <- merge(annual_grid, grid, by = "grid_id")
area_names <- read.csv("data/area_names.csv", colClasses = "character")
```

大表使用 `data.table` 可减少内存消耗。做全年渔具地图或热点组成时，建议逐月读明细，先筛选或聚合，再合并中间结果。对浏览器地图，建议在 R 预先汇总到适合显示的分辨率。保留原始 0.1° 表来计算网格排名，图上的合并或截尾只用于显示。

## 数据口径

- `fishing_hours` 是 GFW 从 AIS 估计的捕鱼活动时长，`hours` 是 AIS 观测到的在场时长，单位均为小时。数据说明的是 2023 年内被观测到的活动。AIS 覆盖、船旗识别与渔具分类均有限制。
- 明细保留零捕鱼时长记录。没有记录的网格月份与已观测到的零值是两种情况。A 页计算活跃网格集中度时，用全年汇总后捕鱼时长大于零的网格作分母。
- `flag` 原样保留。`flag_group` 将 `UNKNOWN` 与 `UNKNOWN-*` 合并为 `UNKNOWN`，把 `UNK` 标为 `UNK_UNRESOLVED`。T12 的前三个已知船旗排除这两个类别，分母包含两者的时长。`flag` 表示 GFW 船旗分类，作业不应把未知后缀当成船旗。
- `geartype = fishing` 表示未细分渔具。保留上层和细分类别的原值。自定义合并可用一对一映射另行计算。
- 海区是按网格中心匹配的 **FAO 主要海洋渔区**。仅相交同一海区的多个几何部件时仍匹配一次。没有命中的网格记为 `UNMATCHED`，命中多个不同渔区的网格记为 `AMBIGUOUS`。海区分析可把非匹配类别单列，去除时应写清范围。网格中心分配是海区边界处的近似。
- `mmsi_present` 是原始聚合计数，跨网格、月份或分组重复出现的 MMSI 无法从该列去重。共享汇总只聚合时长。

## 清洗和复现

- 原始数据是 Global Fishing Watch 2025 年发布的 v3.0，文件 `fleet-monthly-csvs-10-v3-2023.zip`，MD5 `c7ddb54e8cf0b89aa30a9fea588e6253`。原始 ZIP 可在 [Zenodo](https://doi.org/10.5281/zenodo.14982712) 下载。GFW 数据按 CC BY-NC 4.0 标注，报告和图表注明来源。
- 官方字段解释见 [GFW Fleet README](https://zenodo.org/records/14982712/files/README-fleet-v3.txt?download=1)。关于 AIS 接收与船旗误分类，见 [GFW 已知问题](https://zenodo.org/records/14982712/files/README-known-issues-v3.txt?download=1)。
- `sources/fao_major.geojson` 是 [FAO Fisheries GeoServer](https://firms.fao.org/fishery/geoserver/gwc/demo) 的 `fifao:FAO_MAJOR` 边界快照。渔区定义见 [FAO CWP Handbook](https://www.fao.org/cwp-on-fishery-statistics/handbook/general-concepts/main-water-areas)。
- `qa/monthly_checks.csv` 记录清洗前后行数、观测时长、捕鱼时长和零值数。`qa/area_coverage.csv` 记录海区匹配覆盖。`qa/area_by_month_checks.csv` 可追溯每月各区域的覆盖。`qa/R_session_info.txt` 记录运行环境。
- 使用 R、`data.table` 和 `sf`。在解压目录执行以下命令，选择一个新的输出目录。

```sh
Rscript scripts/prepare_gfw.R fleet-monthly-csvs-10-v3-2023.zip sources/fao_major.geojson rebuilt
```

读取现成数据无需重跑清洗。报告的数据预处理章节可以直接引用 QA 表中的数值、匹配规则和局限。
