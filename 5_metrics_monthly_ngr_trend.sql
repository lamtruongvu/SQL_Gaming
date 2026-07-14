-- PHASE 2: METRICS — Monthly Gaming NGR (MoM and YoY comparison)
-- Core gaming KPI for the report. Strips out seasonality noise by comparing
-- against both last month and the same month last year.

WITH monthly_ngr AS (
    SELECT
        d.year,
        d.month,
        d.month_name,
        SUM(s.total_ngr) AS total_ngr,
        SUM(s.total_turnover) AS total_turnover,
        SUM(s.total_jackpots) AS total_jackpots,
        AVG(s.avg_hold_pct) AS avg_hold_pct,
        SUM(s.variance_to_theo) AS variance_to_theo
    FROM fact_daily_gaming_summary s
    JOIN dim_date d ON s.date_id = d.date_id
    GROUP BY d.year, d.month, d.month_name
)
SELECT
    curr.year,
    curr.month,
    curr.month_name,
    curr.total_ngr,
    curr.total_turnover,
    curr.total_jackpots,
    curr.avg_hold_pct,
    curr.variance_to_theo,
    prev_month.total_ngr AS prior_month_ngr,
    ROUND(100.0 * (curr.total_ngr - prev_month.total_ngr)/NULLIF(prev_month.total_ngr, 0), 2) AS mom_growth_pct,
    prev_year.total_ngr AS same_month_last_year_ngr,
    ROUND(100.0 * (curr.total_ngr - prev_year.total_ngr)/NULLIF(prev_year.total_ngr, 0), 2) AS yoy_growth_pct,
    prev_month.total_turnover AS prior_month_turnover,
    ROUND(100.0 * (curr.total_turnover - prev_month.total_turnover)/NULLIF(prev_month.total_turnover, 0), 2) AS mom_growth_turnover,
    prev_year.total_turnover AS same_month_last_year_turnover,
    ROUND(100.0 * (curr.total_turnover - prev_year.total_turnover)/NULLIF(prev_year.total_turnover, 0), 2) AS yoy_growth_turnover,
    prev_month.total_jackpots AS prior_month_jackpots,
    ROUND(100.0 * (curr.total_jackpots - prev_month.total_jackpots)/NULLIF(prev_month.total_jackpots, 0), 2) AS mom_growth_jackpots,
    prev_year.total_jackpots AS same_month_last_year_jackpots,
    ROUND(100.0 * (curr.total_jackpots - prev_year.total_jackpots)/NULLIF(prev_year.total_jackpots, 0), 2) AS yoy_growth_jackpots,
    prev_month.avg_hold_pct AS prior_month_avg_hold_pct,
    prev_year.avg_hold_pct AS same_month_last_year_avg_hold_pct,
    prev_month.variance_to_theo AS prior_month_variance_to_theo,
    curr.variance_to_theo - prev_month.variance_to_theo AS mom_growth_variance_to_theo,
    prev_year.variance_to_theo AS same_month_last_year_variance_to_theo,
    curr.variance_to_theo - prev_year.variance_to_theo AS yoy_growth_variance_to_theo
FROM monthly_ngr curr
LEFT JOIN monthly_ngr prev_month
    ON prev_month.year  = CASE WHEN curr.month = 1 THEN curr.year - 1 ELSE curr.year END
   AND prev_month.month = CASE WHEN curr.month = 1 THEN 12 ELSE curr.month - 1 END
LEFT JOIN monthly_ngr prev_year
    ON prev_year.year  = curr.year - 1
   AND prev_year.month = curr.month
WHERE curr.month = 6 AND curr.year = 2024
ORDER BY curr.year, curr.month;
