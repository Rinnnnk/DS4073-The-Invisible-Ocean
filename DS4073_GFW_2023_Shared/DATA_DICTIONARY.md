# 字段字典

| 字段 | 含义 |
|---|---|
| date | 月起始日，2023 年 1 至 12 月。RDS 为 R 日期，CSV 用 ISO 日期字符串 |
| year, month | 原始年份、月份整数，仅明细 |
| cell_ll_lat, cell_ll_lon | 原始 WGS84 十进制度网格左下角，仅明细 |
| grid_id | 共享的整数网格键，由原左下角坐标转换。公式为 `(round(cell_ll_lat * 10) + 900) * 3600 + round(cell_ll_lon * 10) + 1801` |
| lat_center, lon_center | WGS84 十进制度网格中心，原纬经度各加 0.05°。在 `grid_lookup.rds` 内 |
| area_code | FAO 主要海洋渔区代码，或 UNMATCHED / AMBIGUOUS |
| area_name | 英文渔区名称或空间匹配状态，在 `area_names.csv` 内 |
| flag | GFW 原始船旗分类，仅明细 |
| flag_group | 分析用船旗标签，见 README |
| geartype | GFW 原始船舶渔具分类 |
| hours | GFW AIS 观测在场时长，单位小时 |
| fishing_hours | GFW AIS 估计捕鱼活动时长，单位小时 |
| mmsi_present | 原始行中的 MMSI 出现计数，仅明细。累计后的值无法表示独立船数 |
| grids, active_grids | QA 区域表中对应区域的全部观测网格数和全年有正捕鱼时长的网格数 |

`data/detail/2023-MM.rds` 每行一个月、一个网格、一个原始船旗、一个原始渔具组合。
`data/monthly_grid/2023-MM.rds` 每行一个网格，该月由文件名标识。
`data/summary/annual_grid.rds` 每行一个全年观测到的网格。
`data/grid_lookup.rds` 每行一个观测过的唯一网格，可通过 grid_id 连接。
`data/summary/monthly_area_gear_flag.rds` 每行一个月、一个渔区、一个渔具和一个展示船旗组合。
