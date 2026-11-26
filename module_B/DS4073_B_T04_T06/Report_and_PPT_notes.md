# B. Monthly variation of apparent fishing activity
Add your name to each slide. Use about one minute per task.

## T04 · Global monthly activity
**Slide takeaway.** October was the busiest month, at 13.57 million hours.
 - May recorded 5.96 million hours. October was 2.28 times higher.
 - The dashed line is the mean of the 12 monthly totals (9.31 million hours).
 - Position on a common vertical scale supports comparison. A line connects ordered months.
Speaking cue: "In 2023, recorded fishing activity peaked in October. The annual total was 111.71 million estimated hours; the monthly pattern is far from uniform."

## T05 · Calendar-day adjustment
**Slide takeaway.** After dividing by month length, September ranked first.
 - September: 443,511 estimated hours per day across 30 calendar days.
 - October: 437,786 estimated hours per day across 31 calendar days.
 - Use the crossed lines to explain the change in rank. Rank 1 appears at the top. Both sides use the same rank scale.
Speaking cue: "Total hours answer how much activity was recorded over a month. Dividing by days gives a comparable daily average. October's extra day matters because the two totals were close."

## T06 · Which areas account for the global peak?
**Slide takeaway.** Removing the Northwest Pacific shifts the peak from October to July.
 - From May to October, global hours rose by 7.61 million and the Northwest Pacific rose by 7.97 million. The rest fell by 0.35 million hours.
 - Present T06_global_vs_outside_northwest.png on the slide. Keep the heatmap as the supporting view to show that the 17 complete areas peaked in seven different months.
 - In the demo, switch from FAO 61 (October) to FAO 27 (May). The two panels share a month axis. Hover for precise hours; the lower panel compares within-series percentage shares.
Speaking cue: "The global total peaked in October, but the other grid cells taken together peaked in July. From May to October, the Northwest Pacific gained more hours than the global net increase, because activity elsewhere fell slightly. On the area view, switching to the Northeast Atlantic moves the high point to May."

## Report handoff
B used 12 monthly GFW global totals and month-by-FAO-area summaries. It checked that the complete month series agrees with the sum across all area codes, including unmatched grid centres. B computed calendar-day means before ranking the months. For T06, subtracting FAO area 61 yielded a remainder that includes unmatched grid centres. The Plotly overview shows both series on a common absolute scale, and its linked time axis aligns the profile of any complete FAO area with the global series. The heatmap shows within-area shares by month. It keeps missing area-months distinct from zero and marks peaks only for areas with all 12 months recorded. The comparison describes AIS-derived fishing activity estimates for 2023.
