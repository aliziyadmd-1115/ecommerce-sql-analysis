```sql
-- ============================================================
-- OLIST E-COMMERCE DATA ANALYSIS
-- 06_clean_database_build.sql
--
-- Purpose:
-- Build the remaining cleaned relational tables after source
-- data validation and specialized geolocation/category cleaning.
--
-- Previously created clean tables:
--
-- clean.geolocation
--     Created in 03_geolocation_cleaning.sql
--
-- clean.product_category_translation
-- clean.products
--     Created in 05_category_cleaning.sql
--
-- This script creates:
--
-- clean.customers
-- clean.sellers
-- clean.orders
-- clean.order_items
-- clean.payments
-- clean.reviews
--
-- Proper PostgreSQL data types, primary keys, composite keys,
-- and foreign-key constraints are applied.
--
-- Raw source data remains unchanged.
-- ============================================================


-- ============================================================
-- 1. CLEAN CUSTOMERS
-- ============================================================

CREATE TABLE IF NOT EXISTS clean.customers (
    customer_id VARCHAR(32) PRIMARY KEY,

    customer_unique_id VARCHAR(32) NOT NULL,

    customer_zip_code_prefix VARCHAR(5),

    customer_city VARCHAR(100),

    customer_state VARCHAR(2),

    geolocation_id BIGINT,

    CONSTRAINT fk_customer_geolocation
        FOREIGN KEY (geolocation_id)
        REFERENCES clean.geolocation (
            geolocation_id
        )
);


INSERT INTO clean.customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    geolocation_id
)

SELECT
    TRIM(c.customer_id),

    TRIM(c.customer_unique_id),

    NULLIF(
        TRIM(c.customer_zip_code_prefix),
        ''
    ),

    LOWER(
        NULLIF(TRIM(c.customer_city), '')
    ),

    UPPER(
        NULLIF(TRIM(c.customer_state), '')
    ),

    g.geolocation_id

FROM raw.customers c

LEFT JOIN clean.geolocation g
    ON TRIM(c.customer_zip_code_prefix)
       = g.geolocation_zip_code_prefix

ON CONFLICT (customer_id)
DO UPDATE SET

    customer_unique_id =
        EXCLUDED.customer_unique_id,

    customer_zip_code_prefix =
        EXCLUDED.customer_zip_code_prefix,

    customer_city =
        EXCLUDED.customer_city,

    customer_state =
        EXCLUDED.customer_state,

    geolocation_id =
        EXCLUDED.geolocation_id;


-- Observed clean customers:
-- 99,441
--
-- Customers without matching geolocation:
-- 278
--
-- All customer records were preserved.



-- ============================================================
-- 2. CLEAN SELLERS
-- ============================================================

CREATE TABLE IF NOT EXISTS clean.sellers (
    seller_id VARCHAR(32) PRIMARY KEY,

    seller_zip_code_prefix VARCHAR(5),

    seller_city VARCHAR(100),

    seller_state VARCHAR(2),

    geolocation_id BIGINT,

    CONSTRAINT fk_seller_geolocation
        FOREIGN KEY (geolocation_id)
        REFERENCES clean.geolocation (
            geolocation_id
        )
);


INSERT INTO clean.sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    geolocation_id
)

SELECT
    TRIM(s.seller_id),

    NULLIF(
        TRIM(s.seller_zip_code_prefix),
        ''
    ),

    LOWER(
        NULLIF(TRIM(s.seller_city), '')
    ),

    UPPER(
        NULLIF(TRIM(s.seller_state), '')
    ),

    g.geolocation_id

FROM raw.sellers s

LEFT JOIN clean.geolocation g
    ON TRIM(s.seller_zip_code_prefix)
       = g.geolocation_zip_code_prefix

ON CONFLICT (seller_id)
DO UPDATE SET

    seller_zip_code_prefix =
        EXCLUDED.seller_zip_code_prefix,

    seller_city =
        EXCLUDED.seller_city,

    seller_state =
        EXCLUDED.seller_state,

    geolocation_id =
        EXCLUDED.geolocation_id;


-- Observed clean sellers:
-- 3,095
--
-- Sellers without matching geolocation:
-- 7
--
-- All seller records were preserved.



-- ============================================================
-- 3. CLEAN ORDERS
-- ============================================================

CREATE TABLE IF NOT EXISTS clean.orders (
    order_id VARCHAR(32) PRIMARY KEY,

    customer_id VARCHAR(32) NOT NULL,

    order_status VARCHAR(20),

    order_purchase_timestamp TIMESTAMP,

    order_approved_at TIMESTAMP,

    order_delivered_carrier_date TIMESTAMP,

    order_delivered_customer_date TIMESTAMP,

    order_estimated_delivery_date TIMESTAMP,

    CONSTRAINT fk_order_customer
        FOREIGN KEY (customer_id)
        REFERENCES clean.customers (
            customer_id
        )
);


INSERT INTO clean.orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)

SELECT
    TRIM(order_id),

    TRIM(customer_id),

    LOWER(
        NULLIF(TRIM(order_status), '')
    ),

    NULLIF(
        TRIM(order_purchase_timestamp),
        ''
    )::TIMESTAMP,

    NULLIF(
        TRIM(order_approved_at),
        ''
    )::TIMESTAMP,

    NULLIF(
        TRIM(order_delivered_carrier_date),
        ''
    )::TIMESTAMP,

    NULLIF(
        TRIM(order_delivered_customer_date),
        ''
    )::TIMESTAMP,

    NULLIF(
        TRIM(order_estimated_delivery_date),
        ''
    )::TIMESTAMP

FROM raw.orders

ON CONFLICT (order_id)
DO UPDATE SET

    customer_id =
        EXCLUDED.customer_id,

    order_status =
        EXCLUDED.order_status,

    order_purchase_timestamp =
        EXCLUDED.order_purchase_timestamp,

    order_approved_at =
        EXCLUDED.order_approved_at,

    order_delivered_carrier_date =
        EXCLUDED.order_delivered_carrier_date,

    order_delivered_customer_date =
        EXCLUDED.order_delivered_customer_date,

    order_estimated_delivery_date =
        EXCLUDED.order_estimated_delivery_date;


-- Observed clean orders:
-- 99,441
--
-- Orders without valid customers:
-- 0
--
-- Order status distribution:
--
-- delivered    96,478
-- shipped       1,107
-- canceled        625
-- unavailable     609
-- invoiced        314
-- processing      301
-- created           5
-- approved          2



-- ============================================================
-- 4. CLEAN ORDER ITEMS
-- ============================================================

CREATE TABLE IF NOT EXISTS clean.order_items (
    order_id VARCHAR(32) NOT NULL,

    order_item_id INTEGER NOT NULL,

    product_id VARCHAR(32) NOT NULL,

    seller_id VARCHAR(32) NOT NULL,

    shipping_limit_date TIMESTAMP,

    price NUMERIC(10,2),

    freight_value NUMERIC(10,2),

    CONSTRAINT pk_order_items
        PRIMARY KEY (
            order_id,
            order_item_id
        ),

    CONSTRAINT fk_order_item_order
        FOREIGN KEY (order_id)
        REFERENCES clean.orders (
            order_id
        ),

    CONSTRAINT fk_order_item_product
        FOREIGN KEY (product_id)
        REFERENCES clean.products (
            product_id
        ),

    CONSTRAINT fk_order_item_seller
        FOREIGN KEY (seller_id)
        REFERENCES clean.sellers (
            seller_id
        )
);


INSERT INTO clean.order_items (
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)

SELECT
    TRIM(order_id),

    NULLIF(
        TRIM(order_item_id),
        ''
    )::INTEGER,

    TRIM(product_id),

    TRIM(seller_id),

    NULLIF(
        TRIM(shipping_limit_date),
        ''
    )::TIMESTAMP,

    NULLIF(
        TRIM(price),
        ''
    )::NUMERIC(10,2),

    NULLIF(
        TRIM(freight_value),
        ''
    )::NUMERIC(10,2)

FROM raw.order_items

ON CONFLICT (
    order_id,
    order_item_id
)
DO UPDATE SET

    product_id =
        EXCLUDED.product_id,

    seller_id =
        EXCLUDED.seller_id,

    shipping_limit_date =
        EXCLUDED.shipping_limit_date,

    price =
        EXCLUDED.price,

    freight_value =
        EXCLUDED.freight_value;


-- Observed clean order items:
-- 112,650
--
-- Order items without valid order:
-- 0
--
-- Order items without valid product:
-- 0
--
-- Order items without valid seller:
-- 0
--
-- Negative price/freight records:
-- 0



-- ============================================================
-- 5. CLEAN PAYMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS clean.payments (
    order_id VARCHAR(32) NOT NULL,

    payment_sequential INTEGER NOT NULL,

    payment_type VARCHAR(30),

    payment_installments INTEGER,

    payment_value NUMERIC(10,2),

    CONSTRAINT pk_payments
        PRIMARY KEY (
            order_id,
            payment_sequential
        ),

    CONSTRAINT fk_payment_order
        FOREIGN KEY (order_id)
        REFERENCES clean.orders (
            order_id
        )
);


INSERT INTO clean.payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)

SELECT
    TRIM(order_id),

    NULLIF(
        TRIM(payment_sequential),
        ''
    )::INTEGER,

    LOWER(
        NULLIF(TRIM(payment_type), '')
    ),

    NULLIF(
        TRIM(payment_installments),
        ''
    )::INTEGER,

    NULLIF(
        TRIM(payment_value),
        ''
    )::NUMERIC(10,2)

FROM raw.payments

ON CONFLICT (
    order_id,
    payment_sequential
)
DO UPDATE SET

    payment_type =
        EXCLUDED.payment_type,

    payment_installments =
        EXCLUDED.payment_installments,

    payment_value =
        EXCLUDED.payment_value;


-- Observed clean payments:
-- 103,886
--
-- Payments without valid orders:
-- 0
--
-- Negative payment/installment values:
-- 0
--
-- Payment type distribution:
--
-- credit_card     76,795
-- boleto          19,784
-- voucher          5,775
-- debit_card       1,529
-- not_defined          3
--
-- Zero-value payment records:
-- 9
--
-- Of those:
-- 3 use payment_type = not_defined
-- 6 use payment_type = voucher
--
-- These records were retained because no evidence supported
-- deleting or modifying them.



-- ============================================================
-- 6. CLEAN REVIEWS
-- ============================================================

CREATE TABLE IF NOT EXISTS clean.reviews (
    review_id VARCHAR(32) NOT NULL,

    order_id VARCHAR(32) NOT NULL,

    review_score INTEGER,

    review_comment_title TEXT,

    review_comment_message TEXT,

    review_creation_date TIMESTAMP,

    review_answer_timestamp TIMESTAMP,

    CONSTRAINT pk_reviews
        PRIMARY KEY (
            review_id,
            order_id
        ),

    CONSTRAINT fk_review_order
        FOREIGN KEY (order_id)
        REFERENCES clean.orders (
            order_id
        )
);


INSERT INTO clean.reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)

SELECT
    TRIM(review_id),

    TRIM(order_id),

    NULLIF(
        TRIM(review_score),
        ''
    )::INTEGER,

    NULLIF(
        TRIM(review_comment_title),
        ''
    ),

    NULLIF(
        TRIM(review_comment_message),
        ''
    ),

    NULLIF(
        TRIM(review_creation_date),
        ''
    )::TIMESTAMP,

    NULLIF(
        TRIM(review_answer_timestamp),
        ''
    )::TIMESTAMP

FROM raw.reviews

ON CONFLICT (
    review_id,
    order_id
)
DO UPDATE SET

    review_score =
        EXCLUDED.review_score,

    review_comment_title =
        EXCLUDED.review_comment_title,

    review_comment_message =
        EXCLUDED.review_comment_message,

    review_creation_date =
        EXCLUDED.review_creation_date,

    review_answer_timestamp =
        EXCLUDED.review_answer_timestamp;


-- Observed clean reviews:
-- 99,224
--
-- Reviews without valid order:
-- 0
--
-- Review scores outside 1-5:
-- 0
--
-- Missing review scores:
-- 0
--
-- Duplicate (review_id, order_id) combinations:
-- 0



-- ============================================================
-- 7. FINAL CLEAN TABLE ROW COUNTS
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM clean.customers

UNION ALL

SELECT 'sellers', COUNT(*)
FROM clean.sellers

UNION ALL

SELECT 'orders', COUNT(*)
FROM clean.orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM clean.order_items

UNION ALL

SELECT 'products', COUNT(*)
FROM clean.products

UNION ALL

SELECT 'payments', COUNT(*)
FROM clean.payments

UNION ALL

SELECT 'reviews', COUNT(*)
FROM clean.reviews

UNION ALL

SELECT 'product_category_translation', COUNT(*)
FROM clean.product_category_translation

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM clean.geolocation

ORDER BY table_name;


-- Expected / observed row counts:
--
-- customers                     99,441
-- geolocation                   19,015
-- order_items                  112,650
-- orders                        99,441
-- payments                     103,886
-- product_category_translation      74
-- products                      32,951
-- reviews                       99,224
-- sellers                        3,095



-- ============================================================
-- 8. FINAL FOREIGN-KEY VALIDATION
-- ============================================================

SELECT
    'orders_without_customer' AS check_name,
    COUNT(*) AS issue_count
FROM clean.orders o

LEFT JOIN clean.customers c
    ON o.customer_id = c.customer_id

WHERE c.customer_id IS NULL


UNION ALL


SELECT
    'order_items_without_order',
    COUNT(*)
FROM clean.order_items oi

LEFT JOIN clean.orders o
    ON oi.order_id = o.order_id

WHERE o.order_id IS NULL


UNION ALL


SELECT
    'order_items_without_product',
    COUNT(*)
FROM clean.order_items oi

LEFT JOIN clean.products p
    ON oi.product_id = p.product_id

WHERE p.product_id IS NULL


UNION ALL


SELECT
    'order_items_without_seller',
    COUNT(*)
FROM clean.order_items oi

LEFT JOIN clean.sellers s
    ON oi.seller_id = s.seller_id

WHERE s.seller_id IS NULL


UNION ALL


SELECT
    'payments_without_order',
    COUNT(*)
FROM clean.payments p

LEFT JOIN clean.orders o
    ON p.order_id = o.order_id

WHERE o.order_id IS NULL


UNION ALL


SELECT
    'reviews_without_order',
    COUNT(*)
FROM clean.reviews r

LEFT JOIN clean.orders o
    ON r.order_id = o.order_id

WHERE o.order_id IS NULL


UNION ALL


SELECT
    'products_without_category',
    COUNT(*)
FROM clean.products p

LEFT JOIN clean.product_category_translation t
    ON p.product_category_name =
       t.product_category_name

WHERE t.product_category_name IS NULL;


-- Expected/ observed result:
-- 0 for every relationship check.



-- ============================================================
-- 9. FINAL GEOLOCATION COVERAGE
-- ============================================================

SELECT
    'customers_without_geolocation' AS check_name,
    COUNT(*) AS record_count
FROM clean.customers
WHERE geolocation_id IS NULL

UNION ALL

SELECT
    'sellers_without_geolocation',
    COUNT(*)
FROM clean.sellers
WHERE geolocation_id IS NULL;


-- Observed:
--
-- customers_without_geolocation = 278
-- sellers_without_geolocation   = 7
--
-- These records remain available for non-geographic analyses.



-- ============================================================
-- 10. FINAL QUALITY CHECKS
-- ============================================================

SELECT
    'negative_order_item_values' AS check_name,
    COUNT(*) AS issue_count
FROM clean.order_items
WHERE price < 0
   OR freight_value < 0

UNION ALL

SELECT
    'negative_payment_values',
    COUNT(*)
FROM clean.payments
WHERE payment_value < 0
   OR payment_installments < 0

UNION ALL

SELECT
    'invalid_review_scores',
    COUNT(*)
FROM clean.reviews
WHERE review_score < 1
   OR review_score > 5

UNION ALL

SELECT
    'missing_review_scores',
    COUNT(*)
FROM clean.reviews
WHERE review_score IS NULL;


-- Expected/ observed result:
-- 0 for every check.



-- ============================================================
-- STEP 4 FINAL SUMMARY
-- ============================================================
--
-- The Olist source data has now been:
--
-- 1. Loaded into a raw staging schema.
--
-- 2. Profiled for row counts, duplicate keys, missing values,
--    and source-data inconsistencies.
--
-- 3. Validated for primary-key and composite-key candidates.
--
-- 4. Validated for table relationships and orphan records.
--
-- 5. Cleaned for geographic duplication and inconsistencies.
--
-- 6. Cleaned for missing product-category translations and
--    uncategorized products.
--
-- 7. Converted from raw TEXT values into appropriate
--    PostgreSQL analytical data types.
--
-- 8. Structured using primary keys, composite primary keys,
--    foreign keys, and a surrogate geolocation key.
--
-- 9. Validated to ensure transactional records were preserved.
--
-- Step 4 result:
--
-- The clean relational database is ready for SQL business
-- analysis.
--
-- NEXT:
-- Step 5 - SQL Business Analysis
-- ============================================================
```