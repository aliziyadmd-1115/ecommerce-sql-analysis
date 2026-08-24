-- ============================================================
-- OLIST E-COMMERCE DATA ANALYSIS
-- 07_business_analysis.sql
--
-- Stakeholder:
-- E-Commerce Sales & Operations Manager
--
-- Purpose:
-- Analyze marketplace sales, customer behavior, product
-- performance, seller performance, fulfillment, payments,
-- and customer satisfaction.
--
-- Conventions:
-- 1. Sales/GMV metrics use delivered orders only.
-- 2. Product GMV = SUM(order_items.price).
-- 3. Freight is reported separately.
-- 4. AOV = Product GMV / Delivered Orders.
-- 5. Repeat customers use customer_unique_id.
-- 6. Analysis uses clean.* tables only.
-- ============================================================


-- ============================================================
-- QUESTION 1: EXECUTIVE SALES OVERVIEW
-- ============================================================

SELECT
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    ROUND(SUM(oi.price), 2) AS product_gmv,
    ROUND(SUM(oi.freight_value), 2) AS total_freight,
    ROUND(
        SUM(oi.price) / COUNT(DISTINCT o.order_id),
        2
    ) AS average_order_value
FROM clean.orders o
JOIN clean.order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered';

-- Observed results:
-- Delivered orders: 96,478
-- Product GMV: $13,221,498.11
-- Total freight: $2,198,275.64
-- Average order value: $137.04


-- ============================================================
-- QUESTION 2: MONTHLY GMV AND ORDER TREND
--
-- Business Question:
-- How did delivered order volume and product GMV change
-- month by month?
--
-- SQL concepts:
-- JOIN, DATE_TRUNC, COUNT DISTINCT, SUM, GROUP BY, ORDER BY
-- ============================================================

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS order_month,

    COUNT(DISTINCT o.order_id) AS delivered_orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS product_gmv

FROM clean.orders o

JOIN clean.order_items oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'delivered'

GROUP BY
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )

ORDER BY order_month;

-- Observed results:
-- Monthly delivered-order volume and GMV increased substantially
-- throughout 2017 and remained high during 2018.
--
-- Highest delivered-order volume:
-- November 2017 = 7,289 orders
--
-- Highest monthly product GMV:
-- May 2018 = $977,544.69
--
-- Note:
-- 2016 contains very limited transaction activity and should be
-- interpreted cautiously when evaluating month-over-month trends.


-- ============================================================
-- QUESTION 3: MONTH-OVER-MONTH GMV GROWTH
--
-- Business Question:
-- How did product GMV change from one month to the next
-- during the main operating period?
--
-- SQL concepts:
-- CTE, DATE_TRUNC, LAG, window functions,
-- percentage calculation
--
-- Note:
-- Sparse 2016 activity is excluded to avoid misleading
-- percentage changes caused by incomplete early-period data.
-- ============================================================

WITH monthly_sales AS (

    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS order_month,

        SUM(oi.price) AS product_gmv

    FROM clean.orders o

    JOIN clean.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'

    GROUP BY
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )
),

monthly_growth AS (

    SELECT
        order_month,
        product_gmv,

        LAG(product_gmv) OVER (
            ORDER BY order_month
        ) AS previous_month_gmv

    FROM monthly_sales
)

SELECT
    order_month,

    ROUND(product_gmv, 2) AS product_gmv,

    ROUND(previous_month_gmv, 2) AS previous_month_gmv,

    ROUND(
        (
            (product_gmv - previous_month_gmv)
            / NULLIF(previous_month_gmv, 0)
        ) * 100,
        2
    ) AS mom_growth_percent

FROM monthly_growth

ORDER BY order_month;

-- Observed results:
-- GMV increased rapidly during early 2017, including:
-- February 2017: +109.51%
-- March 2017: +53.36%
-- May 2017: +43.64%
-- November 2017: +52.37%
--
-- The largest monthly decline occurred in:
-- December 2017: -26.50%
--
-- GMV recovered in January 2018 by +27.36%.
--
-- During 2018, GMV was comparatively stable, with smaller
-- month-to-month changes than during the growth period in 2017.
--
-- Sparse 2016 activity was excluded from this calculation
-- because it produced misleading growth percentages.


-- ============================================================
-- QUESTION 4: TOP PRODUCT CATEGORIES BY GMV
--
-- Business Question:
-- Which product categories generate the most product GMV
-- and delivered orders?
--
-- SQL concepts:
-- Multiple JOINs, SUM, COUNT DISTINCT, GROUP BY,
-- ORDER BY, LIMIT
-- ============================================================

SELECT
    pct.product_category_name_english AS product_category,

    COUNT(DISTINCT o.order_id) AS delivered_orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS product_gmv

FROM clean.orders o

JOIN clean.order_items oi
    ON o.order_id = oi.order_id

JOIN clean.products p
    ON oi.product_id = p.product_id

JOIN clean.product_category_translation pct
    ON p.product_category_name =
       pct.product_category_name

WHERE o.order_status = 'delivered'

GROUP BY
    pct.product_category_name_english

ORDER BY
    product_gmv DESC

LIMIT 10;

-- Observed results:
-- Health & Beauty generated the highest product GMV:
-- $1,233,131.72 across 8,647 delivered orders.
--
-- Bed, Bath & Table had the highest delivered-order volume:
-- 9,272 orders with $1,023,434.76 in product GMV.
--
-- Watches & Gifts generated the second-highest GMV:
-- $1,166,176.98 from 5,495 delivered orders, indicating
-- comparatively high product value despite lower order volume.
--
-- The five highest-GMV categories were:
-- Health & Beauty
-- Watches & Gifts
-- Bed, Bath & Table
-- Sports & Leisure
-- Computers & Accessories


-- ============================================================
-- QUESTION 5: PRODUCT CATEGORY CUSTOMER SATISFACTION
--
-- Business Question:
-- Which product categories receive the highest and lowest
-- average customer review scores?
--
-- SQL concepts:
-- CTEs, multiple JOINs, AVG, COUNT DISTINCT, GROUP BY,
-- HAVING, ROUND
-- ============================================================

WITH order_reviews AS (

    SELECT
        order_id,
        AVG(review_score) AS avg_order_review

    FROM clean.reviews

    GROUP BY order_id
),

order_categories AS (

    SELECT DISTINCT
        oi.order_id,
        p.product_category_name

    FROM clean.order_items oi

    JOIN clean.products p
        ON oi.product_id = p.product_id
)

SELECT
    pct.product_category_name_english AS product_category,

    COUNT(DISTINCT oc.order_id) AS reviewed_orders,

    ROUND(
        AVG(r.avg_order_review),
        2
    ) AS average_review_score

FROM order_categories oc

JOIN order_reviews r
    ON oc.order_id = r.order_id

JOIN clean.product_category_translation pct
    ON oc.product_category_name =
       pct.product_category_name

GROUP BY
    pct.product_category_name_english

HAVING COUNT(DISTINCT oc.order_id) >= 100

ORDER BY
    average_review_score DESC;

-- Observed results:
--
-- Highest average review scores:
-- Books - General Interest: 4.46 across 508 reviewed orders
-- Books - Technical: 4.40 across 257 reviewed orders
-- Food & Drink: 4.38 across 226 reviewed orders
--
-- Lowest average review scores:
-- Office Furniture: 3.62 across 1,263 reviewed orders
-- Fashion - Male Clothing: 3.70 across 111 reviewed orders
-- Audio: 3.83 across 347 reviewed orders
--
-- Among major high-GMV categories:
-- Health & Beauty: 4.18
-- Sports & Leisure: 4.17
-- Watches & Gifts: 4.07
-- Computers & Accessories: 4.03
-- Bed, Bath & Table: 3.97
--
-- This indicates that high sales volume does not necessarily
-- correspond to higher customer satisfaction. Office Furniture
-- stands out as a potential area for further investigation
-- because it combines a relatively large review sample with
-- the lowest average rating among categories analyzed.


-- ============================================================
-- QUESTION 6: CUSTOMER STATE SALES PERFORMANCE
--
-- Business Question:
-- Which customer states generate the most delivered orders
-- and product GMV?
--
-- SQL concepts:
-- Multiple JOINs, COUNT DISTINCT, SUM, GROUP BY,
-- percentage calculation, window function
-- ============================================================

WITH state_sales AS (

    SELECT
        c.customer_state,

        COUNT(DISTINCT o.order_id) AS delivered_orders,

        SUM(oi.price) AS product_gmv

    FROM clean.customers c

    JOIN clean.orders o
        ON c.customer_id = o.customer_id

    JOIN clean.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_state
)

SELECT
    customer_state,

    delivered_orders,

    ROUND(product_gmv, 2) AS product_gmv,

    ROUND(
        product_gmv
        / SUM(product_gmv) OVER ()
        * 100,
        2
    ) AS gmv_share_percent

FROM state_sales

ORDER BY product_gmv DESC;

-- Observed results:
--
-- São Paulo (SP) was the dominant market:
-- 40,501 delivered orders
-- $5,067,633.16 in product GMV
-- 38.33% of total delivered-order GMV
--
-- Rio de Janeiro (RJ) ranked second:
-- $1,759,651.13 in GMV
-- 13.31% of total GMV
--
-- Minas Gerais (MG) ranked third:
-- $1,552,481.83 in GMV
-- 11.74% of total GMV
--
-- The top three states generated approximately 63.38%
-- of total product GMV.
--
-- The top five states (SP, RJ, MG, RS, PR) generated
-- approximately 73.93% of total product GMV.
--
-- This indicates that marketplace sales were heavily
-- concentrated in a relatively small number of states,
-- particularly São Paulo.


-- ============================================================
-- QUESTION 7: REPEAT CUSTOMER RATE
--
-- Business Question:
-- What percentage of customers placed more than one
-- delivered order?
--
-- SQL concepts:
-- CTE, COUNT DISTINCT, CASE, aggregation,
-- percentage calculation
-- ============================================================

WITH customer_orders AS (

    SELECT
        c.customer_unique_id,

        COUNT(DISTINCT o.order_id) AS delivered_orders

    FROM clean.customers c

    JOIN clean.orders o
        ON c.customer_id = o.customer_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        c.customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,

    COUNT(
        CASE
            WHEN delivered_orders > 1 THEN 1
        END
    ) AS repeat_customers,

    ROUND(
        COUNT(
            CASE
                WHEN delivered_orders > 1 THEN 1
            END
        )::NUMERIC
        / COUNT(*)
        * 100,
        2
    ) AS repeat_customer_percent

FROM customer_orders;

-- Observed results:
--
-- Total customers with at least one delivered order: 93,358
-- Repeat customers: 2,801
-- Repeat customer rate: 3.00%
--
-- Only a small proportion of customers placed more than one
-- delivered order. This suggests that customer retention and
-- repeat purchasing represent potential areas for improvement.


-- ============================================================
-- QUESTION 8: TOP SELLERS AND GMV CONCENTRATION
--
-- Business Question:
-- Which sellers generate the most product GMV, and how much
-- of total marketplace GMV is generated by each top seller?
--
-- SQL concepts:
-- CTE, JOIN, aggregation, RANK, window functions,
-- percentage calculation
-- ============================================================

WITH seller_sales AS (

    SELECT
        oi.seller_id,

        COUNT(DISTINCT o.order_id) AS delivered_orders,

        SUM(oi.price) AS product_gmv

    FROM clean.orders o

    JOIN clean.order_items oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.seller_id
),

seller_rankings AS (

    SELECT
        seller_id,
        delivered_orders,
        product_gmv,

        RANK() OVER (
            ORDER BY product_gmv DESC
        ) AS gmv_rank,

        SUM(product_gmv) OVER () AS total_marketplace_gmv

    FROM seller_sales
)

SELECT
    gmv_rank,

    seller_id,

    delivered_orders,

    ROUND(product_gmv, 2) AS product_gmv,

    ROUND(
        product_gmv
        / total_marketplace_gmv
        * 100,
        2
    ) AS gmv_share_percent

FROM seller_rankings

ORDER BY gmv_rank

LIMIT 10;

-- Observed results:
--
-- The highest-GMV seller generated:
-- $226,987.93 across 1,124 delivered orders
-- representing 1.72% of total marketplace GMV.
--
-- The second-highest seller generated:
-- $217,940.44 and 1.65% of total GMV.
--
-- The top 10 sellers together generated approximately
-- 13.29% of total marketplace GMV.
--
-- No individual seller accounted for more than 2% of GMV,
-- suggesting that marketplace sales were distributed across
-- many sellers rather than being dominated by a small number
-- of vendors.


-- ============================================================
-- QUESTION 9: LATE DELIVERY VS CUSTOMER SATISFACTION
--
-- Business Question:
-- Do orders delivered late receive lower customer
-- review scores than orders delivered on time?
--
-- SQL concepts:
-- CTE, CASE, AVG, COUNT, GROUP BY
-- ============================================================

WITH order_reviews AS (

    SELECT
        order_id,
        AVG(review_score) AS avg_review_score

    FROM clean.reviews

    GROUP BY order_id
),

delivery_analysis AS (

    SELECT
        o.order_id,

        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 'Late'
            ELSE 'On Time'
        END AS delivery_status,

        r.avg_review_score

    FROM clean.orders o

    JOIN order_reviews r
        ON o.order_id = r.order_id

    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
    delivery_status,

    COUNT(*) AS reviewed_orders,

    ROUND(
        AVG(avg_review_score),
        2
    ) AS average_review_score

FROM delivery_analysis

GROUP BY delivery_status

ORDER BY average_review_score DESC;

-- Observed results:
--
-- On-time deliveries:
-- 88,163 reviewed orders
-- Average review score: 4.29
--
-- Late deliveries:
-- 7,661 reviewed orders
-- Average review score: 2.57
--
-- Late deliveries received an average review score
-- 1.72 points lower than on-time deliveries.
--
-- This shows a strong association between delivery
-- performance and customer satisfaction. While this does
-- not prove that late delivery alone caused lower ratings,
-- delivery timeliness appears to be an important factor
-- affecting the customer experience.


-- ============================================================
-- QUESTION 10: LATE DELIVERY RATE BY STATE
--
-- Business Question:
-- Which customer states experience the highest rates
-- of late delivery?
--
-- SQL concepts:
-- JOIN, CASE, conditional aggregation, GROUP BY,
-- HAVING, percentage calculation
-- ============================================================

SELECT
    c.customer_state,

    COUNT(*) AS evaluated_deliveries,

    SUM(
        CASE
            WHEN o.order_delivered_customer_date
                 > o.order_estimated_delivery_date
            THEN 1
            ELSE 0
        END
    ) AS late_deliveries,

    ROUND(
        SUM(
            CASE
                WHEN o.order_delivered_customer_date
                     > o.order_estimated_delivery_date
                THEN 1
                ELSE 0
            END
        )::NUMERIC
        / COUNT(*)
        * 100,
        2
    ) AS late_delivery_rate_percent

FROM clean.orders o

JOIN clean.customers c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL

GROUP BY
    c.customer_state

HAVING COUNT(*) >= 100

ORDER BY
    late_delivery_rate_percent DESC;

-- Observed results:
--
-- Highest late-delivery rates:
-- Alagoas (AL): 23.93% (95 of 397 deliveries)
-- Maranhão (MA): 19.67% (141 of 717 deliveries)
-- Piauí (PI): 15.97% (76 of 476 deliveries)
-- Ceará (CE): 15.32% (196 of 1,279 deliveries)
-- Sergipe (SE): 15.22% (51 of 335 deliveries)
--
-- Rio de Janeiro (RJ) also showed a relatively high
-- late-delivery rate of 13.47% across 12,350 deliveries.
--
-- São Paulo (SP), despite having the highest order volume,
-- had a comparatively low late-delivery rate of 5.89%.
--
-- These results suggest that delivery performance varies
-- substantially by geography and that states such as AL,
-- MA, PI, CE, and RJ may warrant further logistics analysis.


-- ============================================================
-- QUESTION 11: PAYMENT METHOD AND INSTALLMENT PATTERNS
--
-- Business Question:
-- Which payment methods are used most frequently, and how
-- do installment patterns differ across payment methods?
--
-- SQL concepts:
-- CTE, GROUP BY, COUNT, SUM, AVG, window functions,
-- percentage calculation
-- ============================================================

WITH payment_summary AS (

    SELECT
        payment_type,

        COUNT(*) AS payment_records,

        SUM(payment_value) AS total_payment_value,

        AVG(payment_installments) AS avg_installments

    FROM clean.payments

    GROUP BY payment_type
)

SELECT
    payment_type,

    payment_records,

    ROUND(total_payment_value, 2) AS total_payment_value,

    ROUND(avg_installments, 2) AS average_installments,

    ROUND(
        payment_records::NUMERIC
        / SUM(payment_records) OVER ()
        * 100,
        2
    ) AS payment_record_share_percent

FROM payment_summary

ORDER BY payment_records DESC;

-- Observed results:
--
-- Credit cards were the dominant payment method:
-- 76,795 payment records
-- $12,542,084.19 in total payment value
-- 73.92% of all payment records
-- Average installments: 3.51
--
-- Boleto was the second-most common method:
-- 19,784 payment records
-- $2,869,361.27 in payment value
-- 19.04% of payment records
--
-- Voucher and debit card payments represented much smaller
-- shares at 5.56% and 1.47%, respectively.
--
-- Credit cards were also the only major payment method with
-- an average installment count above 1, showing that customers
-- frequently used installment financing for credit purchases.
--
-- The three not_defined payment records had zero payment value,
-- consistent with the records retained during data cleaning.


-- ============================================================
-- QUESTION 12: PRODUCT CATEGORY GMV GROWTH
--
-- Business Question:
-- Which established product categories gained or lost the
-- most GMV between January-August 2017 and
-- January-August 2018?
--
-- SQL concepts:
-- CTE, multiple JOINs, CASE, conditional aggregation,
-- percentage calculation, NULLIF, RANK, window functions
--
-- Note:
-- Only categories with at least $10,000 in Jan-Aug 2017 GMV
-- are included to avoid misleading growth percentages caused
-- by very small starting values.
-- ============================================================

WITH category_year_sales AS (

    SELECT
        pct.product_category_name_english AS product_category,

        EXTRACT(
            YEAR FROM o.order_purchase_timestamp
        )::INTEGER AS order_year,

        SUM(oi.price) AS product_gmv

    FROM clean.orders o

    JOIN clean.order_items oi
        ON o.order_id = oi.order_id

    JOIN clean.products p
        ON oi.product_id = p.product_id

    JOIN clean.product_category_translation pct
        ON p.product_category_name =
           pct.product_category_name

    WHERE o.order_status = 'delivered'
      AND o.order_purchase_timestamp >= '2017-01-01'
      AND o.order_purchase_timestamp < '2018-09-01'
      AND EXTRACT(MONTH FROM o.order_purchase_timestamp)
          BETWEEN 1 AND 8

    GROUP BY
        pct.product_category_name_english,
        EXTRACT(YEAR FROM o.order_purchase_timestamp)
),

category_comparison AS (

    SELECT
        product_category,

        SUM(
            CASE
                WHEN order_year = 2017
                THEN product_gmv
                ELSE 0
            END
        ) AS gmv_2017,

        SUM(
            CASE
                WHEN order_year = 2018
                THEN product_gmv
                ELSE 0
            END
        ) AS gmv_2018

    FROM category_year_sales

    GROUP BY product_category
),

category_growth AS (

    SELECT
        product_category,
        gmv_2017,
        gmv_2018,

        gmv_2018 - gmv_2017 AS gmv_change,

        (
            (gmv_2018 - gmv_2017)
            / NULLIF(gmv_2017, 0)
        ) * 100 AS growth_percent

    FROM category_comparison

    WHERE gmv_2017 >= 10000
      AND gmv_2018 > 0
)

SELECT
    product_category,

    ROUND(gmv_2017, 2) AS jan_aug_2017_gmv,

    ROUND(gmv_2018, 2) AS jan_aug_2018_gmv,

    ROUND(gmv_change, 2) AS gmv_change,

    ROUND(growth_percent, 2) AS growth_percent,

    RANK() OVER (
        ORDER BY growth_percent DESC
    ) AS growth_rank

FROM category_growth

ORDER BY growth_percent DESC;

-- Observed results:
--
-- Highest percentage GMV growth among established categories:
-- Home Appliances 2: +729.71%
-- Home Appliances: +311.01%
-- Baby: +268.56%
-- Stationery: +260.29%
-- Electronics: +244.23%
--
-- Several large categories also experienced strong growth:
-- Watches & Gifts: +241.98% (+$486,717.34)
-- Health & Beauty: +210.33% (+$512,202.80)
-- Housewares: +207.23% (+$264,288.92)
-- Sports & Leisure: +138.63% (+$300,441.93)
-- Computers & Accessories: +131.22% (+$281,638.03)
--
-- Health & Beauty produced the largest absolute GMV increase
-- among the categories analyzed, adding $512,202.80.
--
-- Two established categories declined:
-- Home Comfort: -3.30%
-- Market Place: -49.86%
--
-- These results show that percentage growth and absolute
-- dollar growth should be considered together. Smaller
-- categories such as Home Appliances 2 grew fastest by
-- percentage, while major categories such as Health & Beauty
-- and Watches & Gifts contributed substantially larger
-- increases in total GMV.