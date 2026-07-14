-- PHASE 3: SEGMENTATION — RFM (Recency/Frequency/Monetary)
-- Scores every active member 1-5 on each dimension using quintiles, then
-- combines into a segment label. This is the basis for targeted campaigns.

WITH member_rfm_raw AS (
    SELECT
        m.member_id,
        m.loyalty_tier,
        DATEDIFF('2024-06-30', MAX(v.visit_date)) AS recency_days,
        COUNT(v.visit_id) AS frequency,
        SUM(v.total_spend) AS monetary
    FROM dim_members m
    JOIN fact_member_visits v ON m.member_id = v.member_id
    WHERE m.is_active = 1
    GROUP BY m.member_id, m.loyalty_tier
),
rfm_scored AS (
    SELECT
        *,
        -- NTILE assigns 1 to the first rows and 5 to the last rows.
        NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score, -- DESC ensures customers with the lowest recency_days receive the highest score (5).
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score, -- Highest purchase frequency receives score 5.
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score -- Highest monetary value receives score 5.
    FROM member_rfm_raw
)
SELECT
    member_id,
    loyalty_tier,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    r_score + f_score + m_score AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Cannot Lose Them'
        WHEN r_score >= 4 AND f_score <= 2 THEN 'New/Promising'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernating'
        ELSE 'Needs Attention'
    END AS rfm_segment

FROM rfm_scored
ORDER BY rfm_total DESC, monetary DESC;

-- Segment-level summary for the report
WITH scored AS (
    SELECT
        m.member_id,
        DATEDIFF('2024-06-30', MAX(v.visit_date)) AS recency_days,
        COUNT(v.visit_id) AS frequency,
        SUM(v.total_spend) AS monetary,
        NTILE(5) OVER (ORDER BY DATEDIFF('2024-06-30', MAX(v.visit_date)) ASC) AS r_score, -- Higher score = more recent visit (lower recency_days)
        NTILE(5) OVER (ORDER BY COUNT(v.visit_id) DESC) AS f_score, -- Higher score = more visits
        NTILE(5) OVER (ORDER BY SUM(v.total_spend) DESC) AS m_score -- Higher score = higher spending
    FROM dim_members m
    JOIN fact_member_visits v ON m.member_id = v.member_id
    WHERE m.is_active = 1
    GROUP BY m.member_id
),
segmented AS (
    SELECT
        member_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
            WHEN r_score = 5 AND f_score <= 2 THEN 'New Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Promising'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Cant Lose Them'
            WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernating'
            ELSE 'Needs Attention'
        END AS rfm_segment
    FROM scored
)
SELECT
    rfm_segment,
    COUNT(*) AS member_count,
    ROUND(AVG(recency_days), 1) AS avg_recency_days,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary
FROM segmented
GROUP BY rfm_segment
ORDER BY member_count DESC;
