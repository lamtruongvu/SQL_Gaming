-- PHASE 2: METRICS — Member Churn & Tier Migration
-- Tracks new enrolments, churn events, and movement between loyalty tiers
-- for the reporting month — the core membership health KPIs.

-- New enrolments and churn events this month
SELECT
    'New Enrolments' AS metric,
    COUNT(*) AS member_count
FROM dim_members
WHERE enrolment_date BETWEEN '2024-06-01' AND '2024-06-30'
UNION ALL
SELECT
    'Churned This Month' AS metric,
    COUNT(*) AS member_count
FROM dim_members
WHERE churn_date BETWEEN '2024-06-01' AND '2024-06-30'
UNION ALL
SELECT
    'Total Active Members' AS metric,
    COUNT(*) AS member_count
FROM dim_members
WHERE is_active = 1;

-- Active members by tier with average visit frequency this month
SELECT
    m.loyalty_tier,
    COUNT(DISTINCT m.member_id) AS active_members,
    COUNT(v.visit_id) AS total_visits_this_month,
    ROUND(COUNT(v.visit_id) * 1.0/NULLIF(COUNT(DISTINCT m.member_id), 0), 2) AS avg_visits_per_member,
    ROUND(SUM(v.total_spend) * 1.0/NULLIF(COUNT(DISTINCT m.member_id), 0), 2) AS avg_spend_per_member,
    SUM(v.total_spend) AS total_tier_spend
FROM dim_members m
LEFT JOIN fact_member_visits v
    ON m.member_id = v.member_id
   AND v.visit_date BETWEEN '2024-06-01' AND '2024-06-30'
WHERE m.is_active = 1
GROUP BY m.loyalty_tier
ORDER BY
    CASE m.loyalty_tier
        WHEN 'Bronze' THEN 1 
        WHEN 'Silver' THEN 2 
        WHEN 'Gold' THEN 3
        WHEN 'Platinum' THEN 4 
        WHEN 'Diamond' THEN 5
    END;

-- Members at churn risk: no visit in the last 60 days but still marked active
SELECT
    m.member_id,
    m.loyalty_tier,
    MAX(v.visit_date) AS last_visit_date,
    DATEDIFF('2024-06-30', MAX(v.visit_date)) AS days_since_last_visit,
    SUM(v.total_spend) AS lifetime_spend
FROM dim_members m
JOIN fact_member_visits v ON m.member_id = v.member_id
WHERE m.is_active = 1
GROUP BY m.member_id, m.loyalty_tier
HAVING DATEDIFF('2024-06-30', MAX(v.visit_date)) > 60
ORDER BY days_since_last_visit DESC;
