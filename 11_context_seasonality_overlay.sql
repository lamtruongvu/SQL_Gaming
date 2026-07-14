-- PHASE 4: CONTEXT — Seasonality & Public Holiday Overlay
-- Explains WHY a number moved. Joins dim_date flags onto the daily NGR
-- summary so a variance can be attributed to a calendar effect rather than
-- a genuine trend before it goes in the report narrative.

SELECT
    s.summary_date,
    d.day_name,
    d.is_weekend,
    d.is_public_holiday,
    d.is_footy_finals,
    d.is_christmas_period,
    s.gaming_area,
    s.total_ngr,
    AVG(s.total_ngr) OVER (
        PARTITION BY s.gaming_area
        ORDER BY s.summary_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_avg_ngr
FROM fact_daily_gaming_summary s
JOIN dim_date d ON s.date_id = d.date_id
WHERE s.summary_date BETWEEN '2026-06-01' AND '2026-06-30'
ORDER BY s.gaming_area, s.summary_date;

-- Day-type comparison: how much does a public holiday or footy finals day move NGR?
SELECT
    CASE
        WHEN d.is_public_holiday = 1 THEN 'Public Holiday'
        WHEN d.is_footy_finals = 1 THEN 'Footy Finals'
        WHEN d.is_weekend = 1 THEN 'Weekend'
        ELSE 'Regular Weekday'
    END AS day_type,
    COUNT(DISTINCT s.summary_date) AS day_count,
    SUM(s.total_ngr) AS total_ngr,
    ROUND(SUM(s.total_ngr)/COUNT(DISTINCT s.summary_date), 2) AS avg_ngr_per_day
FROM fact_daily_gaming_summary s
JOIN dim_date d ON s.date_id = d.date_id
WHERE s.summary_date BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY
    CASE
        WHEN d.is_public_holiday = 1 THEN 'Public Holiday'
        WHEN d.is_footy_finals = 1 THEN 'Footy Finals'
        WHEN d.is_weekend = 1 THEN 'Weekend'
        ELSE 'Regular Weekday'
    END
ORDER BY avg_ngr_per_day DESC;
