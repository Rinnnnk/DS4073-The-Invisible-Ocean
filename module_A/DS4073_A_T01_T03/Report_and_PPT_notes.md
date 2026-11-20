# Report and presentation notes

## A. Spatial distribution of apparent fishing activity

**Data abstraction.** The Global Fishing Watch 2023 monthly fleet data describe one month, 0.1-degree grid cell, flag and gear combination per source row. We use estimated fishing hours as the quantitative measure. T01 and T03 use annual grid totals. T02 uses the shared assignment of cell centres to FAO major marine areas. Both grouping methods reconcile to **111,712,128.6941 fishing hours**.

### T01. Locate high-hour cells

**Design.** Each colored tile is a 0.1-degree cell. Position preserves longitude and latitude, and color encodes annual hours. A log(1 + hours) color scale shows variation across a wide range of values. Gray cells indicate recorded zero values, and blank ocean indicates no record.

**Result.** A strong concentration is visible along the coast of eastern Asia. The highest-hour cell was centred at **119.35° E, 35.05° N**, near the coast of eastern China, with **316,398.92 estimated fishing hours** summed across vessels. Of the **2,040,786** recorded cells, **847,485** had zero estimated fishing hours. The map shows totals per angular grid cell. Physical cell size varies by latitude.

### T02. Compare marine areas

**Design.** Rank FAO marine areas by estimated fishing hours. Bar length encodes totals on a common zero baseline. Unmatched grid centres appear in a separate gray bar.

**Result.** The **Northwest Pacific (61)** accounted for **68.29 million hours**, or **61.13%** of the global total. The next two areas were the **Northeast Atlantic (27)** with **9.01 million hours**, and the **Western Indian Ocean (51)** with **6.79 million hours**. The global denominator includes **2.34 million hours (2.09%)** from grid centres outside the FAO marine polygons. These are area totals with no area-size adjustment.

### T03. Quantify concentration

**Design.** Order the cells with positive annual fishing hours from highest to lowest. The curve uses position to show the cumulative shares of active cells and fishing hours. The dashed line represents equal hours per active cell. Points mark the top 1%, 5% and 10%.

**Result.** The top **1%** (**11,934** cells), top **5%** (**59,666** cells) and top **10%** (**119,331** cells) contributed **65.98%**, **85.16%** and **90.21%** of annual hours. The denominator for the cell percentages is **1,193,301** cells with positive hours. Cutoffs round up to a whole cell and ties use grid ID. The shares measure proportions of grid cells.

**Limitations.** GFW estimates apparent fishing activity from AIS. Coverage and classification vary across locations. Grid-centre assignment approximates the region of activity in cells that cross a marine boundary.

## Three task slides

| Slide | Figure | Main point to say |
|---|---|---|
| T01. Where were fishing hours observed? | `T01_annual_grid_map.png` | Explain the grid and color scale. Point out the highest-hour cell and explain what a gray or blank cell means. |
| T02. Which marine areas had the most hours? | `T02_fao_area_ranking.png` | The Northwest Pacific contributed 61.13% of estimated global hours. The global denominator includes the 2.09% unmatched share. |
| T03. How concentrated were the hours? | `T03_grid_concentration.png` | The top 1% of active cells contributed 65.98% of hours. Explain the gap between the curve and the dashed diagonal. |

Add your name to each slide. The implementation uses data.table to join and summarize, sf to read the land polygons, and ggplot2 for the three charts.
