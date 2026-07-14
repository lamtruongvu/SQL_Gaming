-- PHASE 1: DATA QUALITY — NULL/Missing Field Audit
-- Run this FIRST every month, before any aggregation.
-- Flags every known DQ issue in dim_members so issues are caught before
-- they distort the report's headline numbers.

SELECT
    COUNT(*) AS total_members,
    SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END) AS null_dob,
    SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END) AS null_dob,
    SUM(CASE WHEN date_of_birth > CURRENT_DATE THEN 1 ELSE 0 END) AS future_dob,
    SUM(CASE WHEN date_of_birth < '1900-01-01' THEN 1 ELSE 0 END) AS impossible_dob,
    SUM(CASE WHEN email IS NULL THEN 1 ELSE 0 END)AS null_email,
    SUM(CASE WHEN email = 'noemail@noemail.com' THEN 1 ELSE 0 END) AS placeholder_email,
    SUM(CASE WHEN phone IS NULL THEN 1 ELSE 0 END) AS null_phone,
    SUM(CASE WHEN postcode IS NULL THEN 1 ELSE 0 END) AS null_postcode,
    SUM(CASE WHEN postcode = '9999' THEN 1 ELSE 0 END) AS invalid_postcode,
    SUM(CASE WHEN churn_date IS NOT NULL AND is_active = 1 THEN 1 ELSE 0 END) AS churn_active_mismatch,
    ROUND(100.0 * SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END)/COUNT(*), 2) AS pct_null_dob,
    ROUND(100.0 * SUM(CASE WHEN email IS NULL OR email = 'noemail@noemail.com' THEN 1 ELSE 0 END)/COUNT(*), 2) AS pct_bad_email
FROM dim_members;

-- Drill-down: list the actual problem rows for the data steward to action
SELECT
    member_id, first_name, last_name, date_of_birth, email, phone, postcode,
    is_active, churn_date,
    CASE
        WHEN date_of_birth IS NULL THEN 'NULL_DOB'
        WHEN date_of_birth > CURRENT_DATE THEN 'FUTURE_DOB'
        WHEN date_of_birth < '1900-01-01' THEN 'IMPOSSIBLE_DOB'
        WHEN email IS NULL THEN 'NULL_EMAIL'
        WHEN email = 'noemail@noemail.com' THEN 'PLACEHOLDER_EMAIL'
        WHEN postcode = '9999' THEN 'INVALID_POSTCODE'
        WHEN churn_date IS NOT NULL AND is_active = 1 THEN 'CHURN_ACTIVE_MISMATCH'
    END AS dq_issue
FROM dim_members
WHERE date_of_birth IS NULL
   OR date_of_birth > CURRENT_DATE
   OR date_of_birth < '1900-01-01'
   OR email IS NULL
   OR email = 'noemail@noemail.com'
   OR postcode = '9999'
   OR (churn_date IS NOT NULL AND is_active = 1)
ORDER BY dq_issue, member_id;
