-- PHASE 1: DATA QUALITY - Duplicate Ledger Detection
-- fact_loyalty_points_ledger has an intentional ~0.5% duplicate rate.
-- This finds exact duplicates (same member, date, type, points, reference)
-- so they can be excluded from the points balance reconciliation.

WITH duplicate_groups AS (
    SELECT
        member_id,
        transaction_date,
        transaction_type,
        source,
        points,
        reference_id,
        COUNT(*) AS occurrence_count,
        STRING_AGG(ledger_id, ', ') AS duplicate_ledger_ids
    FROM fact_loyalty_points_ledger
    GROUP BY member_id, transaction_date, transaction_type, source, points, reference_id
    HAVING COUNT(*) > 1
)
SELECT
    *,
    (occurrence_count - 1) AS excess_rows_to_remove
FROM duplicate_groups
ORDER BY occurrence_count DESC;

-- Summary: total impact of duplicates on points totals
SELECT
    COUNT(*) AS total_ledger_rows,
    SUM(CASE WHEN dup_rank > 1 THEN 1 ELSE 0 END) AS duplicate_rows,
    SUM(CASE WHEN dup_rank > 1 THEN points ELSE 0 END) AS points_overstated_by
FROM (
    SELECT
        ledger_id,
        points,
        ROW_NUMBER() OVER (
            PARTITION BY member_id, transaction_date, transaction_type, source, points, reference_id
            ORDER BY ledger_id
        ) AS dup_rank
    FROM fact_loyalty_points_ledger
) ranked;
