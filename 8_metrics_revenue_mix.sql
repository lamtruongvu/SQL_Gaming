-- PHASE 2: METRICS — Revenue Mix (Gaming vs F&B, Member vs Walk-in)
-- Breaks total club revenue into its constituent streams for the report's
-- revenue composition chart.

-- Gaming vs F&B vs other, from member visits
SELECT
    SUM(gaming_spend) AS gaming_revenue,
    SUM(food_spend) AS food_revenue,
    SUM(bar_spend) AS bar_revenue,
    SUM(other_spend) AS other_revenue,
    SUM(total_spend) AS total_member_revenue,
    ROUND(100.0 * SUM(gaming_spend)/SUM(total_spend), 2) AS gaming_pct,
    ROUND(100.0 * SUM(food_spend + bar_spend)/SUM(total_spend), 2) AS fb_pct
FROM fact_member_visits
WHERE visit_date BETWEEN '2024-06-01' AND '2024-06-30';

-- Member vs walk-in F&B contribution (from POS, which captures non-member traffic)
SELECT
    CASE WHEN member_id IS NULL OR member_id = '' THEN 'Walk-in' 
        ELSE 'Member' 
    END AS customer_type,
    COUNT(*) AS transaction_count,
    SUM(total_amount) AS total_revenue,
    ROUND(AVG(total_amount), 2) AS avg_transaction_value
FROM fact_pos_transactions
WHERE txn_date BETWEEN '2024-06-01' AND '2024-06-30' AND is_void = 0
GROUP BY CASE WHEN member_id IS NULL OR member_id = '' THEN 'Walk-in' ELSE 'Member' END;

-- F&B revenue by outlet and category for the month
SELECT
    outlet,
    category,
    SUM(total_amount) AS revenue,
    COUNT(*) AS txn_count,
    ROUND(AVG(total_amount), 2) AS avg_basket
FROM fact_pos_transactions
WHERE txn_date BETWEEN '2024-06-01' AND '2024-06-30'
  AND is_void = 0
  AND unit_price > 0
GROUP BY outlet, category
ORDER BY outlet, revenue DESC;
