-- PHASE 3: SEGMENTATION — Promotion Campaign ROI
-- Evaluates which promo types and channels deliver the best return,
-- and checks reactivation campaign effectiveness against churned members.

-- ROI by promo type and channel
SELECT
    promo_type,
    channel,
    COUNT(*) AS members_targeted,
    SUM(is_redeemed) AS redemptions,
    ROUND(100.0 * SUM(is_redeemed) / COUNT(*), 2) AS redemption_rate_pct,
    SUM(campaign_cost) AS total_cost,
    SUM(revenue_uplift) AS total_uplift,
    ROUND(SUM(revenue_uplift) / NULLIF(SUM(campaign_cost), 0), 2) AS roi_ratio
FROM fact_promotions
WHERE offer_start_date BETWEEN '2026-06-01' AND '2026-06-30'
GROUP BY promo_type, channel
ORDER BY roi_ratio DESC;

-- Reactivation offer effectiveness: did churned members come back?
SELECT
    p.promo_id,
    p.member_id,
    m.churn_date,
    p.offer_start_date,
    p.is_redeemed,
    p.redemption_date,
    CASE WHEN v.member_id IS NOT NULL THEN 1 ELSE 0 END AS returned_to_visit
FROM fact_promotions p
JOIN dim_members m ON p.member_id = m.member_id
LEFT JOIN fact_member_visits v
    ON v.member_id = p.member_id
   AND v.visit_date > p.offer_start_date
   AND v.visit_date <= DATE_ADD(p.offer_end_date, INTERVAL 30 DAY)
WHERE p.promo_type = 'Reactivation Offer'
  AND m.churn_date IS NOT NULL
ORDER BY p.offer_start_date DESC;

-- Reactivation summary rate
SELECT
    COUNT(DISTINCT p.member_id) AS churned_members_targeted,
    COUNT(DISTINCT v.member_id) AS members_who_returned,
    ROUND(100.0 * COUNT(DISTINCT v.member_id)/NULLIF(COUNT(DISTINCT p.member_id), 0), 2) AS reactivation_rate_pct
FROM fact_promotions p
JOIN dim_members m ON p.member_id = m.member_id
LEFT JOIN fact_member_visits v
    ON v.member_id = p.member_id
   AND v.visit_date > p.offer_start_date
   AND v.visit_date <= DATE_ADD(p.offer_end_date, INTERVAL 30 DAY)
WHERE p.promo_type = 'Reactivation Offer'
  AND m.churn_date IS NOT NULL;
