-- PHASE 2: METRICS — Machine & Gaming Area Performance
-- Ranks gaming areas and individual machines by NGR per machine per day —
-- the standard EGM performance KPI clubs use to decide floor reallocation.

-- Gaming area ranking for the reporting month
SELECT
    gaming_area,
    SUM(total_ngr) AS month_ngr,
    SUM(total_turnover) AS month_turnover,
    AVG(active_machines) AS avg_active_machines,
    ROUND(SUM(total_ngr) / NULLIF(SUM(active_machines), 0), 2) AS ngr_per_machine_per_day,
    AVG(avg_hold_pct) AS avg_hold_pct,
    SUM(variance_to_theo) AS variance_to_theo
FROM fact_daily_gaming_summary
WHERE summary_date BETWEEN '2024-06-01' AND '2024-06-30'
GROUP BY gaming_area
ORDER BY ngr_per_machine_per_day DESC;

-- Top 20 and bottom 20 individual machines by NGR for the month
WITH machine_month AS (
    SELECT
        gs.machine_id,
        gm.machine_type,
        gm.manufacturer,
        gm.gaming_area,
        gm.denomination,
        SUM(gs.net_gaming_revenue) AS month_ngr,
        SUM(gs.turnover) AS month_turnover,
        COUNT(*) AS session_count,
        AVG(gs.actual_hold_pct) AS avg_actual_hold,
        AVG(gs.theoretical_hold_pct) AS avg_theoretical_hold
    FROM fact_gaming_sessions gs
    JOIN dim_gaming_machines gm ON gs.machine_id = gm.machine_id
    WHERE gs.session_date BETWEEN '2024-06-01' AND '2024-06-30'
    GROUP BY gs.machine_id, gm.machine_type, gm.manufacturer, gm.gaming_area, gm.denomination
)
SELECT * FROM (
    SELECT *, RANK() OVER (ORDER BY month_ngr DESC) AS ngr_rank
    FROM machine_month
) ranked
WHERE ngr_rank <= 20 OR ngr_rank > (SELECT COUNT(*) FROM machine_month) - 20
ORDER BY ngr_rank;
