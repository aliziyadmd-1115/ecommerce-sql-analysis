-- ============================================================
-- OLIST E-COMMERCE DATA ANALYSIS
-- 02_data_validation.sql
--
-- Purpose:
-- Profile and validate the imported raw data before building
-- the cleaned relational database.
--
-- Checks include:
-- - Row counts
-- - Primary-key candidate uniqueness
-- - Composite-key candidate uniqueness
-- - Missing key values
-- - Review key analysis
-- - Geolocation duplication
-- - Geographic consistency
-- ============================================================


-- ============================================================
-- 1. ROW COUNT VALIDATION
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM raw.customers

UNION ALL

SELECT 'orders', COUNT(*)
FROM raw.orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM raw.order_items

UNION ALL

SELECT 'products', COUNT(*)
FROM raw.products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM raw.sellers

UNION ALL

SELECT 'payments', COUNT(*)
FROM raw.payments

UNION ALL

SELECT 'reviews', COUNT(*)
FROM raw.reviews

UNION ALL

SELECT 'product_category_translation', COUNT(*)
FROM raw.product_category_translation

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM raw.geolocation;


-- Observed row counts:
--
-- customers                     99,441
-- orders                        99,441
-- order_items                  112,650
-- products                      32,951
-- sellers                        3,095
-- payments                     103,886
-- reviews                       99,224
-- product_category_translation      71
-- geolocation                1,000,163



-- ============================================================
-- 2. PRIMARY KEY CANDIDATE UNIQUENESS
-- ============================================================

-- Customers

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM raw.customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Observed result: 0 rows


-- Orders

SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM raw.orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Observed result: 0 rows


-- Products

SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM raw.products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Observed result: 0 rows


-- Sellers

SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM raw.sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- Observed result: 0 rows



-- ============================================================
-- 3. COMPOSITE KEY VALIDATION
-- ============================================================

-- Order Items:
-- Candidate PK = (order_id, order_item_id)

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM raw.order_items
GROUP BY
    order_id,
    order_item_id
HAVING COUNT(*) > 1;

-- Observed result: 0 rows


-- Payments:
-- Candidate PK = (order_id, payment_sequential)

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS duplicate_count
FROM raw.payments
GROUP BY
    order_id,
    payment_sequential
HAVING COUNT(*) > 1;

-- Observed result: 0 rows



-- ============================================================
-- 4. PRIMARY KEY NULL / BLANK VALIDATION
-- ============================================================
-- Primary-key columns must also contain no NULL or blank values.

SELECT
    'customers.customer_id' AS key_checked,
    COUNT(*) AS missing_key_values
FROM raw.customers
WHERE NULLIF(TRIM(customer_id), '') IS NULL

UNION ALL

SELECT
    'orders.order_id',
    COUNT(*)
FROM raw.orders
WHERE NULLIF(TRIM(order_id), '') IS NULL

UNION ALL

SELECT
    'products.product_id',
    COUNT(*)
FROM raw.products
WHERE NULLIF(TRIM(product_id), '') IS NULL

UNION ALL

SELECT
    'sellers.seller_id',
    COUNT(*)
FROM raw.sellers
WHERE NULLIF(TRIM(seller_id), '') IS NULL

UNION ALL

SELECT
    'order_items composite key',
    COUNT(*)
FROM raw.order_items
WHERE NULLIF(TRIM(order_id), '') IS NULL
   OR NULLIF(TRIM(order_item_id), '') IS NULL

UNION ALL

SELECT
    'payments composite key',
    COUNT(*)
FROM raw.payments
WHERE NULLIF(TRIM(order_id), '') IS NULL
   OR NULLIF(TRIM(payment_sequential), '') IS NULL;

-- Observed result:
-- 0 missing values for all proposed primary-key columns.



-- ============================================================
-- 5. REVIEWS KEY VALIDATION
-- ============================================================

-- Test review_id alone.

SELECT
    review_id,
    COUNT(*) AS duplicate_count
FROM raw.reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

-- Observed result:
-- 789 duplicated review_id values


-- Test order_id alone.

SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM raw.reviews
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Observed result:
-- 547 duplicated order_id values


-- Test (review_id, order_id).

SELECT
    review_id,
    order_id,
    COUNT(*) AS duplicate_count
FROM raw.reviews
GROUP BY
    review_id,
    order_id
HAVING COUNT(*) > 1;

-- Observed result: 0 rows


-- Check for missing values in the proposed composite key.

SELECT COUNT(*) AS missing_review_key_values
FROM raw.reviews
WHERE NULLIF(TRIM(review_id), '') IS NULL
   OR NULLIF(TRIM(order_id), '') IS NULL;

-- Observed result: 0


-- Conclusion:
-- (review_id, order_id) is a valid composite primary key.



-- ============================================================
-- 6. GEOLOCATION DISTINCT ZIP PREFIXES
-- ============================================================

SELECT
    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS unique_zip_prefixes
FROM raw.geolocation;

-- Observed result: 19,015



-- ============================================================
-- 7. DUPLICATED ZIP + LATITUDE + LONGITUDE COMBINATIONS
-- ============================================================

SELECT COUNT(*) AS duplicate_coordinate_combinations
FROM (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng
    FROM raw.geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng
    HAVING COUNT(*) > 1
) AS duplicates;

-- Observed result: 131,709



-- ============================================================
-- 8. EXCESS DUPLICATE COORDINATE ROWS
-- ============================================================

SELECT
    SUM(duplicate_count - 1) AS excess_duplicate_rows
FROM (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        COUNT(*) AS duplicate_count
    FROM raw.geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng
    HAVING COUNT(*) > 1
) AS duplicates;

-- Observed result: 280,015



-- ============================================================
-- 9. COMPLETELY IDENTICAL GEOLOCATION GROUPS
-- ============================================================

SELECT COUNT(*) AS duplicate_full_row_groups
FROM (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    FROM raw.geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    HAVING COUNT(*) > 1
) AS duplicates;

-- Observed result: 128,178



-- ============================================================
-- 10. ZIP PREFIXES ASSOCIATED WITH MULTIPLE STATES
-- ============================================================

SELECT
    geolocation_zip_code_prefix,
    COUNT(DISTINCT geolocation_state) AS state_count
FROM raw.geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(DISTINCT geolocation_state) > 1;

-- Observed result:
-- 8 ZIP prefixes



-- ============================================================
-- 11. ZIP PREFIXES ASSOCIATED WITH MULTIPLE CITIES
-- ============================================================

SELECT COUNT(*) AS zip_prefixes_with_multiple_cities
FROM (
    SELECT
        geolocation_zip_code_prefix
    FROM raw.geolocation
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT(DISTINCT geolocation_city) > 1
) AS multiple_cities;

-- Observed result: 8,556



-- ============================================================
-- 12. INSPECT STATE CONFLICTS
-- ============================================================

SELECT
    geolocation_zip_code_prefix,
    geolocation_state,
    COUNT(*) AS occurrences
FROM raw.geolocation
WHERE geolocation_zip_code_prefix IN (
    SELECT
        geolocation_zip_code_prefix
    FROM raw.geolocation
    GROUP BY geolocation_zip_code_prefix
    HAVING COUNT(DISTINCT geolocation_state) > 1
)
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_state
ORDER BY
    geolocation_zip_code_prefix,
    occurrences DESC;


-- Observed state conflicts:
--
-- 02116 SP 12
-- 02116 RN 1
--
-- 04011 SP 178
-- 04011 AC 1
--
-- 21550 RJ 170
-- 21550 AC 1
--
-- 23056 RJ 60
-- 23056 AC 1
--
-- 72915 GO 40
-- 72915 DF 1
--
-- 78557 MT 96
-- 78557 RO 1
--
-- 79750 MS 179
-- 79750 RS 1
--
-- 80630 PR 122
-- 80630 SC 1
--
-- Each conflicting ZIP prefix has one clearly dominant state.



-- ============================================================
-- VALIDATION SUMMARY
-- ============================================================
--
-- customers.customer_id:
--     Unique candidate PK
--
-- orders.order_id:
--     Unique candidate PK
--
-- products.product_id:
--     Unique candidate PK
--
-- sellers.seller_id:
--     Unique candidate PK
--
-- order_items:
--     (order_id, order_item_id) is unique
--
-- payments:
--     (order_id, payment_sequential) is unique
--
-- reviews:
--     review_id alone is not unique
--     order_id alone is not unique
--     (review_id, order_id) is unique and contains no blanks
--
-- geolocation:
--     Raw data contains substantial duplication and inconsistent
--     city/state mappings.
--
--     Existing source columns should not be used directly as
--     a primary key for the raw geolocation table.
--
-- Raw source tables remain unchanged.
-- ============================================================