-- ============================================================
-- OLIST E-COMMERCE DATA ANALYSIS
-- 01_database_setup.sql
--
-- Purpose:
-- Create the raw staging schema and raw tables used to import
-- the original Olist CSV files.
--
-- The raw layer preserves source data without applying
-- cleaning rules, primary keys, foreign keys, or transformations.
-- ============================================================


-- ============================================================
-- 1. CREATE RAW SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS raw;


-- ============================================================
-- 2. CUSTOMERS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);


-- ============================================================
-- 3. GEOLOCATION
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat TEXT,
    geolocation_lng TEXT,
    geolocation_city TEXT,
    geolocation_state TEXT
);


-- ============================================================
-- 4. ORDERS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);


-- ============================================================
-- 5. ORDER ITEMS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.order_items (
    order_id TEXT,
    order_item_id TEXT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price TEXT,
    freight_value TEXT
);


-- ============================================================
-- 6. PRODUCTS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght TEXT,
    product_description_lenght TEXT,
    product_photos_qty TEXT,
    product_weight_g TEXT,
    product_length_cm TEXT,
    product_height_cm TEXT,
    product_width_cm TEXT
);


-- ============================================================
-- 7. SELLERS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.sellers (
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);


-- ============================================================
-- 8. PAYMENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.payments (
    order_id TEXT,
    payment_sequential TEXT,
    payment_type TEXT,
    payment_installments TEXT,
    payment_value TEXT
);


-- ============================================================
-- 9. REVIEWS
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.reviews (
    review_id TEXT,
    order_id TEXT,
    review_score TEXT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);


-- ============================================================
-- 10. PRODUCT CATEGORY TRANSLATION
-- ============================================================

CREATE TABLE IF NOT EXISTS raw.product_category_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);


-- ============================================================
-- SETUP SUMMARY
-- ============================================================
--
-- Raw tables created:
--
-- raw.customers
-- raw.geolocation
-- raw.orders
-- raw.order_items
-- raw.products
-- raw.sellers
-- raw.payments
-- raw.reviews
-- raw.product_category_translation
--
-- Raw columns are initially stored as TEXT to reduce the risk
-- of import failures caused by missing values, timestamps,
-- formatting differences, or unexpected source-data issues.
--
-- Validation, cleaning, type conversion, keys, and constraints
-- are handled in later SQL scripts.
-- ============================================================