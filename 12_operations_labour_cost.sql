-- PHASE 5: OPERATIONS — Labour Cost vs Revenue
-- The standard club operations KPI executives watch monthly: labour cost
-- as a percentage of total revenue, plus overtime exposure by department.

WITH daily_revenue AS (
    SELECT visit_date, SUM(total_spend) AS total_revenue
    FROM fact_member_visits
    WHERE visit_date BETWEEN '2024-06-01' AND '2024-06-30'
    GROUP BY visit_date
),
daily_labour AS (
    SELECT
        work_date,
        SUM(gross_pay + ph_loading) AS total_labour_cost,
        SUM(total_hours) AS total_hours,
        SUM(overtime_hours) AS total_overtime_hours
    FROM fact_staff_roster
    WHERE work_date BETWEEN '2024-06-01' AND '2024-06-30'
    GROUP BY work_date
)
SELECT
    r.work_date,
    d.day_name,
    d.is_public_holiday,
    r.total_labour_cost,
    r.total_hours,
    r.total_overtime_hours,
    rev.total_revenue,
    ROUND(100.0 * r.total_labour_cost/NULLIF(rev.total_revenue, 0), 2) AS labour_cost_pct
FROM daily_labour r
JOIN dim_date d ON d.full_date = r.work_date
LEFT JOIN daily_revenue rev ON rev.visit_date = r.work_date
ORDER BY r.work_date;

-- Department-level labour cost and overtime for the month
SELECT
    department,
    SUM(gross_pay + ph_loading) AS total_labour_cost,
    SUM(total_hours) AS total_hours,
    SUM(overtime_hours) AS total_overtime_hours,
    ROUND(100.0 * SUM(overtime_hours)/NULLIF(SUM(total_hours), 0), 2) AS overtime_pct_of_hours,
    ROUND(AVG(gross_pay/NULLIF(total_hours, 0)), 2) AS avg_effective_hourly_cost
FROM fact_staff_roster
-- WHERE work_date BETWEEN :report_start_date AND :report_end_date
WHERE work_date BETWEEN '2024-06-01' AND '2024-06-30'
GROUP BY department
ORDER BY total_labour_cost DESC;
