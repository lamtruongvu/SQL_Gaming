-- PHASE 1: DATA QUALITY — Negative POS Amounts & Void Reconciliation
-- representing unvoided reversals — i.e. a refund that was never flagged
-- with is_void = 1. This breaks revenue totals if not caught.

-- Find negative-amount transactions that are NOT flagged as void
SELECT
    txn_id, member_id, txn_date, outlet, category,
    quantity, unit_price, total_amount, is_void, payment_method
FROM fact_pos_transactions
WHERE unit_price < 0 AND is_void = 0
ORDER BY txn_date DESC;

-- Monthly impact: how much revenue is being understated by unflagged reversals
SELECT
    YEAR(txn_date) AS txn_year,
    MONTH(txn_date) AS txn_month,
    COUNT(*) AS unflagged_negative_txns,
    SUM(total_amount) AS revenue_impact_aud
FROM fact_pos_transactions
WHERE unit_price < 0 AND is_void = 0
GROUP BY YEAR(txn_date), MONTH(txn_date)
ORDER BY txn_year, txn_month;

-- Cross-check: void flag vs actual amount sign consistency
SELECT
    is_void,
    SUM(CASE WHEN unit_price < 0 THEN 1 ELSE 0 END) AS negative_amount_count,
    SUM(CASE WHEN unit_price >= 0 THEN 1 ELSE 0 END) AS positive_amount_count,
    COUNT(*) AS total
FROM fact_pos_transactions
GROUP BY is_void;
