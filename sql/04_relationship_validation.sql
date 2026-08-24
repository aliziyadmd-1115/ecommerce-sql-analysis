-- ============================================================
-- OLIST E-COMMERCE DATA ANALYSIS
-- 04_relationship_validation.sql
--
-- Purpose:
-- Validate relationships between raw source tables before
-- enforcing foreign-key constraints in the cleaned data model.
--
-- Checks include:
-- - Orphan records
-- - Missing category translations
-- - Category lookup uniqueness
-- - Missing product categories
-- - Transactional impact of missing categories
-- ============================================================


-- ============================================================
-- 1. ORDERS -> CUSTOMERS
-- ============================================================

SELECT COUNT(*) AS orphan_orders
FROM raw.orders o

LEFT JOIN raw.customers c
    ON o.customer_id = c.customer_id

WHERE c.customer_id IS NULL;

-- Observed result: 0



-- ============================================================
-- 2. ORDER ITEMS -> ORDERS
-- ============================================================

SELECT COUNT(*) AS orphan_order_items
FROM raw.order_items oi

LEFT JOIN raw.orders o
    ON oi.order_id = o.order_id

WHERE o.order_id IS NULL;

-- Observed result: 0



-- ============================================================
-- 3. ORDER ITEMS -> PRODUCTS
-- ============================================================

SELECT COUNT(*) AS missing_products
FROM raw.order_items oi

LEFT JOIN raw.products p
    ON oi.product_id = p.product_id

WHERE p.product_id IS NULL;

-- Observed result: 0



-- ============================================================
-- 4. ORDER ITEMS -> SELLERS
-- ============================================================

SELECT COUNT(*) AS missing_sellers
FROM raw.order_items oi

LEFT JOIN raw.sellers s
    ON oi.seller_id = s.seller_id

WHERE s.seller_id IS NULL;

-- Observed result: 0



-- ============================================================
-- 5. PAYMENTS -> ORDERS
-- ============================================================

SELECT COUNT(*) AS orphan_payments
FROM raw.payments p

LEFT JOIN raw.orders o
    ON p.order_id = o.order_id

WHERE o.order_id IS NULL;

-- Observed result: 0



-- ============================================================
-- 6. REVIEWS -> ORDERS
-- ============================================================

SELECT COUNT(*) AS orphan_reviews
FROM raw.reviews r

LEFT JOIN raw.orders o
    ON r.order_id = o.order_id

WHERE o.order_id IS NULL;

-- Observed result: 0



-- ============================================================
-- 7. PRODUCTS -> PRODUCT CATEGORY TRANSLATION
-- ============================================================
-- Identify categories used by products but missing from the
-- supplied English translation lookup.

SELECT DISTINCT
    p.product_category_name

FROM raw.products p

LEFT JOIN raw.product_category_translation t
    ON p.product_category_name = t.product_category_name

WHERE NULLIF(
          TRIM(p.product_category_name),
          ''
      ) IS NOT NULL

  AND t.product_category_name IS NULL

ORDER BY p.product_category_name;


-- Observed result:
--
-- pc_gamer
-- portateis_cozinha_e_preparadores_de_alimentos
--
-- Two category values are missing from the supplied lookup.



-- ============================================================
-- 8. CATEGORY TRANSLATION KEY UNIQUENESS
-- ============================================================

SELECT
    product_category_name,
    COUNT(*) AS duplicate_count

FROM raw.product_category_translation

GROUP BY product_category_name

HAVING COUNT(*) > 1;

-- Observed result: 0 rows



-- ============================================================
-- 9. CATEGORY TRANSLATION MISSING KEYS
-- ============================================================

SELECT COUNT(*) AS missing_category_names
FROM raw.product_category_translation
WHERE NULLIF(
          TRIM(product_category_name),
          ''
      ) IS NULL;

-- Observed result: 0



-- ============================================================
-- 10. PRODUCTS AFFECTED BY MISSING TRANSLATIONS
-- ============================================================

SELECT
    p.product_category_name,
    COUNT(*) AS product_count

FROM raw.products p

WHERE p.product_category_name IN (
    'pc_gamer',
    'portateis_cozinha_e_preparadores_de_alimentos'
)

GROUP BY p.product_category_name

ORDER BY p.product_category_name;


-- Observed results:
--
-- pc_gamer = 3 products
--
-- portateis_cozinha_e_preparadores_de_alimentos
-- = 10 products
--
-- Total products affected = 13



-- ============================================================
-- 11. PRODUCTS WITH NO CATEGORY
-- ============================================================

SELECT COUNT(*) AS products_missing_category
FROM raw.products
WHERE NULLIF(
          TRIM(product_category_name),
          ''
      ) IS NULL;

-- Observed result: 610



-- ============================================================
-- 12. PURCHASED ITEMS WITH MISSING PRODUCT CATEGORY
-- ============================================================

SELECT COUNT(*) AS order_items_with_missing_category
FROM raw.order_items oi

JOIN raw.products p
    ON oi.product_id = p.product_id

WHERE NULLIF(
          TRIM(p.product_category_name),
          ''
      ) IS NULL;

-- Observed result: 1,603



-- ============================================================
-- RELATIONSHIP VALIDATION SUMMARY
-- ============================================================
--
-- orders.customer_id -> customers.customer_id
--     0 orphan records
--
-- order_items.order_id -> orders.order_id
--     0 orphan records
--
-- order_items.product_id -> products.product_id
--     0 orphan records
--
-- order_items.seller_id -> sellers.seller_id
--     0 orphan records
--
-- payments.order_id -> orders.order_id
--     0 orphan records
--
-- reviews.order_id -> orders.order_id
--     0 orphan records
--
-- Product category relationship:
--
--     2 category values are missing from the original
--     translation lookup:
--
--         pc_gamer
--         portateis_cozinha_e_preparadores_de_alimentos
--
--     13 products use those categories.
--
--     610 products contain no category at all.
--
--     Those uncategorized products occur in 1,603
--     purchased order-item records.
--
-- Raw source tables remain unchanged.
--
-- These category issues are resolved in:
-- 05_category_cleaning.sql
-- ============================================================