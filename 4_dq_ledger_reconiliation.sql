-- PHASE 1: DATA QUALITY — Points Ledger Reconciliation
-- Verifies that dim_members.lifetime_points_earned/redeemed actually match
-- the sum of transactions in fact_loyalty_points_ledger. Any drift indicates
-- a broken ETL job or a missed update during the month.

WITH ledger_totals AS (
    SELECT
        member_id,
        SUM(CASE WHEN points > 0 THEN points ELSE 0 END) AS ledger_earned,
        SUM(CASE WHEN points < 0 THEN -points ELSE 0 END) AS ledger_redeemed
    FROM fact_loyalty_points_ledger
    GROUP BY member_id
)
SELECT
    m.member_id,
    m.lifetime_points_earned AS member_table_earned,
    lt.ledger_earned,
    m.lifetime_points_earned - lt.ledger_earned AS earned_variance,
    m.lifetime_points_redeemed AS member_table_redeemed,
    lt.ledger_redeemed,
    m.lifetime_points_redeemed - lt.ledger_redeemed AS redeemed_variance
FROM dim_members m
JOIN ledger_totals lt ON m.member_id = lt.member_id
WHERE m.lifetime_points_earned   <> lt.ledger_earned
   OR m.lifetime_points_redeemed <> lt.ledger_redeemed
ORDER BY ABS(m.lifetime_points_earned - lt.ledger_earned) DESC;

-- Summary count of how many members are out of balance
SELECT
    COUNT(*) AS members_with_variance
FROM dim_members m
JOIN (
    SELECT
        member_id,
        SUM(CASE WHEN points > 0 THEN points ELSE 0 END) AS ledger_earned,
        SUM(CASE WHEN points < 0 THEN -points ELSE 0 END) AS ledger_redeemed
    FROM fact_loyalty_points_ledger
    GROUP BY member_id
) lt ON m.member_id = lt.member_id
WHERE m.lifetime_points_earned <> lt.ledger_earned
   OR m.lifetime_points_redeemed <> lt.ledger_redeemed;
