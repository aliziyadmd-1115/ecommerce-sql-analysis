-- ============================================================
-- OLIST E-COMMERCE DATA ANALYSIS
-- 05_category_cleaning.sql
--
-- Purpose:
-- Resolve product-category data-quality issues identified during
-- relationship validation and create a cleaned products table.
--
-- Issues identified:
--
-- 1. Two categories were missing from the English translation
--    lookup.
--
-- 2. 610 products contained no product category.
--
-- 3. Those uncategorized products occurred in 1,603 purchased
--    order-item records.
--
-- Raw source tables remain unchanged.
-- ============================================================


-- ============================================================
-- 1. CREATE CLEAN SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS clean;


-- ============================================================
-- 2. CREATE CLEAN CATEGORY LOOKUP
-- ============================================================

CREATE TABLE IF NOT EXISTS clean.product_category_translation (
    product_category_name VARCHAR(100) PRIMARY KEY,
    product_category_name_english VARCHAR(100) NOT NULL
);


-- ============================================================
-- 3. COPY ORIGINAL CATEGORY TRANSLATIONS
-- ============================================================

INSERT INTO clean.product_category_translation (
    product_category_name,
    product_category_name_english
)

SELECT
    TRIM(product_category_name),
    TRIM(product_category_name_english)

FROM raw.product_category_translation

ON CONFLICT (product_category_name)
DO UPDATE SET
    product_category_name_english =
        EXCLUDED.product_category_name_english;


-- Original supplied lookup contains 71 categories.



-- ============================================================
-- 4. ADD TWO MISSING CATEGORY TRANSLATIONS
-- ============================================================

INSERT INTO clean.product_category_translation (
    product_category_name,
    product_category_name_english
)

VALUES
    (
        'pc_gamer',
        'PC Gaming'
    ),
    (
        'portateis_cozinha_e_preparadores_de_alimentos',
        'Portable Kitchen and Food Preparation Appliances'
    )

ON CONFLICT (product_category_name)
DO UPDATE SET
    product_category_name_english =
        EXCLUDED.product_category_name_english;


-- Category count should now be 73.



-- ============================================================
-- 5. ADD UNKNOWN / UNCATEGORIZED CATEGORY
-- ============================================================

INSERT INTO clean.product_category_translation (
    product_category_name,
    product_category_name_english
)

VALUES (
    'unknown',
    'Unknown / Uncategorized'
)

ON CONFLICT (product_category_name)
DO UPDATE SET
    product_category_name_english =
        EXCLUDED.product_category_name_english;


-- Final clean category count should be 74.



-- ============================================================
-- 6. VALIDATE FINAL CATEGORY COUNT
-- ============================================================

SELECT COUNT(*) AS final_category_count
FROM clean.product_category_translation;

-- Observed result: 74



-- ============================================================
-- 7. VALIDATE CATEGORY KEY UNIQUENESS
-- ============================================================

SELECT
    product_category_name,
    COUNT(*) AS duplicate_count

FROM clean.product_category_translation

GROUP BY product_category_name

HAVING COUNT(*) > 1;

-- Observed result: 0 rows



-- ============================================================
-- 8. CREATE CLEAN PRODUCTS TABLE
-- ============================================================
--
-- Improvements from raw.products:
--
-- product_name_lenght
--     becomes product_name_length
--
-- product_description_lenght
--     becomes product_description_length
--
-- Missing categories become:
--     unknown
--
-- Proper analytical data types are applied.
--
-- A foreign-key relationship is enforced between products
-- and the cleaned category lookup.
-- ============================================================

CREATE TABLE IF NOT EXISTS clean.products (
    product_id VARCHAR(32) PRIMARY KEY,

    product_category_name VARCHAR(100) NOT NULL,

    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER,

    CONSTRAINT fk_product_category
        FOREIGN KEY (product_category_name)
        REFERENCES clean.product_category_translation (
            product_category_name
        )
);


-- ============================================================
-- 9. POPULATE CLEAN PRODUCTS
-- ============================================================

INSERT INTO clean.products (
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)

SELECT
    TRIM(product_id),

    COALESCE(
        NULLIF(
            TRIM(product_category_name),
            ''
        ),
        'unknown'
    ),

    NULLIF(
        TRIM(product_name_lenght),
        ''
    )::INTEGER,

    NULLIF(
        TRIM(product_description_lenght),
        ''
    )::INTEGER,

    NULLIF(
        TRIM(product_photos_qty),
        ''
    )::INTEGER,

    NULLIF(
        TRIM(product_weight_g),
        ''
    )::INTEGER,

    NULLIF(
        TRIM(product_length_cm),
        ''
    )::INTEGER,

    NULLIF(
        TRIM(product_height_cm),
        ''
    )::INTEGER,

    NULLIF(
        TRIM(product_width_cm),
        ''
    )::INTEGER

FROM raw.products

ON CONFLICT (product_id)
DO UPDATE SET

    product_category_name =
        EXCLUDED.product_category_name,

    product_name_length =
        EXCLUDED.product_name_length,

    product_description_length =
        EXCLUDED.product_description_length,

    product_photos_qty =
        EXCLUDED.product_photos_qty,

    product_weight_g =
        EXCLUDED.product_weight_g,

    product_length_cm =
        EXCLUDED.product_length_cm,

    product_height_cm =
        EXCLUDED.product_height_cm,

    product_width_cm =
        EXCLUDED.product_width_cm;


-- ============================================================
-- 10. VALIDATE PRODUCT COUNT
-- ============================================================

SELECT COUNT(*) AS clean_product_count
FROM clean.products;

-- Observed result: 32,951



-- ============================================================
-- 11. VALIDATE UNKNOWN CATEGORY CONVERSION
-- ============================================================

SELECT COUNT(*) AS unknown_products
FROM clean.products
WHERE product_category_name = 'unknown';

-- Observed result: 610



-- ============================================================
-- 12. CHECK FOR NULL CATEGORIES
-- ============================================================

SELECT COUNT(*) AS null_product_categories
FROM clean.products
WHERE product_category_name IS NULL;

-- Observed result: 0



-- ============================================================
-- 13. CHECK PRODUCT -> CATEGORY RELATIONSHIP
-- ============================================================

SELECT DISTINCT
    p.product_category_name

FROM clean.products p

LEFT JOIN clean.product_category_translation t
    ON p.product_category_name =
       t.product_category_name

WHERE t.product_category_name IS NULL;

-- Observed result: 0 rows



-- ============================================================
-- 14. VALIDATE PRODUCT PRIMARY KEY
-- ============================================================

SELECT
    product_id,
    COUNT(*) AS duplicate_count

FROM clean.products

GROUP BY product_id

HAVING COUNT(*) > 1;

-- Observed result: 0 rows



-- ============================================================
-- 15. INSPECT PRODUCT DISTRIBUTION BY CATEGORY
-- ============================================================

SELECT
    t.product_category_name_english,
    COUNT(*) AS product_count

FROM clean.products p

JOIN clean.product_category_translation t
    ON p.product_category_name =
       t.product_category_name

GROUP BY
    t.product_category_name_english

ORDER BY
    product_count DESC;


-- ============================================================
-- CLEANING SUMMARY
-- ============================================================
--
-- Original category translations:
--     71
--
-- Missing translations added:
--     2
--
-- Unknown category added:
--     1
--
-- Final category lookup:
--     74
--
-- Raw products:
--     32,951
--
-- Clean products:
--     32,951
--
-- Products assigned to Unknown / Uncategorized:
--     610
--
-- Originally uncategorized products represented in order items:
--     1,603 records
--
-- NULL product categories after cleaning:
--     0
--
-- Unmatched category relationships after cleaning:
--     0
--
-- Duplicate product IDs after cleaning:
--     0
--
-- Raw source data remains unchanged.
-- ============================================================