# Olist E-Commerce SQL Analysis

## Project Overview

This project analyzes the Brazilian Olist e-commerce marketplace using PostgreSQL. The goal was to transform raw transactional data into a clean relational database and use SQL to identify meaningful insights related to sales performance, customer behavior, product categories, sellers, delivery performance, payments, and customer satisfaction.

The project follows an end-to-end SQL workflow that includes:

- Raw data ingestion
- Data quality validation
- Data cleaning and standardization
- Relational database design
- Primary and foreign key validation
- Business analysis using SQL
- Business findings and recommendations

## Stakeholder

**E-Commerce Sales & Operations Manager**

The stakeholder is responsible for monitoring marketplace performance and making decisions related to sales growth, customer retention, product performance, seller performance, logistics, and customer experience.

## Business Objective

The objective of this analysis is to answer business questions that can help the stakeholder:

- Understand overall marketplace sales performance
- Identify high-performing and growing product categories
- Analyze geographic sales concentration
- Measure customer retention
- Evaluate seller performance
- Understand customer payment behavior
- Identify delivery-performance issues
- Examine the relationship between delivery performance and customer satisfaction

## Key Project Metrics

| Metric | Result |
|---|---:|
| Delivered Orders | 96,478 |
| Product GMV | $13.22M |
| Average Order Value | $137.04 |
| Total Freight | $2.20M |
| Customers with Delivered Orders | 93,358 |
| Repeat Customer Rate | 3.00% |
| Highest-GMV State | São Paulo (38.33%) |
| On-Time Delivery Avg. Review | 4.29 |
| Late Delivery Avg. Review | 2.57 |

## Tools & Technologies

- **PostgreSQL**
- **pgAdmin 4**
- **SQL**
- **Visual Studio Code**
- **Microsoft Excel** for the data dictionary
- **GitHub** for project documentation and portfolio presentation

## Dataset

This project uses the Brazilian E-Commerce Public Dataset by Olist. The dataset contains approximately 100,000 orders placed between 2016 and 2018 and includes information about customers, products, sellers, payments, reviews, order items, and geographic locations.

The project uses nine source datasets:

| Table | Purpose |
|---|---|
| `customers` | Customer identifiers and location information |
| `orders` | Order status and purchase/delivery timestamps |
| `order_items` | Products, sellers, prices, and freight associated with each order |
| `products` | Product category and product attribute information |
| `sellers` | Seller identifiers and locations |
| `payments` | Payment methods, installments, and payment values |
| `reviews` | Customer review scores and comments |
| `geolocation` | ZIP-code-level geographic information |
| `product_category_translation` | Portuguese-to-English product category translations |

## Database Architecture

The PostgreSQL database was organized into two main schemas:

### `raw` Schema

The `raw` schema preserves the original imported datasets. Source columns were initially stored as text during ingestion to reduce import errors and maintain the original data before transformation.

### `clean` Schema

The `clean` schema contains validated, standardized, and relationally structured tables used for business analysis.

Key cleaning steps included:

- Converting numeric and timestamp fields to appropriate PostgreSQL data types
- Validating primary and composite keys
- Checking foreign-key relationships for orphan records
- Standardizing customer and seller location fields
- Resolving duplicate geolocation records
- Creating one analytical geolocation record per ZIP-code prefix
- Adding missing product category translations
- Assigning uncategorized products to an `Unknown / Uncategorized` category
- Preserving valid zero-value and uncommon payment records rather than deleting them without evidence

## Data Pipeline

The project follows this workflow:

```text
Raw CSV Files
      ↓
raw Schema
      ↓
Data Validation
      ↓
Data Cleaning & Standardization
      ↓
clean Schema
      ↓
Relationship Validation
      ↓
SQL Business Analysis
      ↓
Findings & Recommendations

| Validation Check                  | Result |
| --------------------------------- | -----: |
| Orders without customers          |      0 |
| Order items without orders        |      0 |
| Order items without products      |      0 |
| Order items without sellers       |      0 |
| Payments without orders           |      0 |
| Reviews without orders            |      0 |
| Products without valid categories |      0 |
| Invalid review scores             |      0 |
| Negative order-item values        |      0 |
| Negative payment values           |      0 |


## SQL Business Analysis

The cleaned database was used to answer 12 business questions covering sales, customers, products, geography, sellers, payments, delivery performance, and customer satisfaction.

| # | Business Question | Key SQL Techniques |
|---|---|---|
| 1 | What are total delivered orders, GMV, freight, and average order value? | `JOIN`, `SUM`, `COUNT DISTINCT`, `ROUND` |
| 2 | How have monthly GMV and order volume changed over time? | `DATE_TRUNC`, `GROUP BY`, aggregation |
| 3 | How did GMV change month over month? | CTEs, `LAG()`, window functions |
| 4 | Which product categories generate the most GMV? | Multiple `JOIN`s, aggregation, `LIMIT` |
| 5 | Which categories receive the highest and lowest review scores? | CTEs, `AVG`, `HAVING` |
| 6 | Which customer states generate the most GMV? | CTE, geographic aggregation, window functions |
| 7 | What percentage of customers make repeat purchases? | CTE, `CASE`, `customer_unique_id` |
| 8 | Which sellers generate the most GMV? | CTEs, `RANK()`, window functions |
| 9 | Are late deliveries associated with lower review scores? | CTEs, `CASE`, conditional analysis |
| 10 | Which states have the highest late-delivery rates? | Conditional aggregation, percentages |
| 11 | Which payment methods are used most frequently? | CTE, `AVG`, `SUM`, window functions |
| 12 | Which established product categories are gaining or losing GMV? | CTEs, `CASE`, `NULLIF`, `RANK()` |

### SQL Skills Demonstrated

- Multi-table joins
- Aggregate functions
- Common Table Expressions (CTEs)
- Conditional logic with `CASE`
- `GROUP BY` and `HAVING`
- Date and timestamp analysis
- Conditional aggregation
- Percentage calculations
- `LAG()` for month-over-month analysis
- `RANK()` for performance rankings
- Window functions
- Data-grain management to prevent duplicate aggregation

### Example: Month-over-Month GMV Growth

A window function was used to compare each month's GMV with the previous month:

```sql
LAG(product_gmv) OVER (
    ORDER BY order_month
) AS previous_month_gmv
```

This analysis showed rapid marketplace growth during 2017, including a **52.37% increase in November 2017**, followed by a **26.50% decline in December** and a **27.36% recovery in January 2018**.

### Example: Delivery Performance and Reviews

Orders were classified using conditional logic:

```sql
CASE
    WHEN order_delivered_customer_date
         > order_estimated_delivery_date
    THEN 'Late'
    ELSE 'On Time'
END
```

The results showed a substantial difference in customer satisfaction:

| Delivery Status | Reviewed Orders | Average Review Score |
|---|---:|---:|
| On Time | 88,163 | 4.29 |
| Late | 7,661 | 2.57 |

Late deliveries received ratings approximately **1.72 points lower** than on-time deliveries, indicating a strong association between delivery performance and customer satisfaction.

### Example: Repeat Customer Analysis

Repeat purchasing was measured using `customer_unique_id` rather than the order-specific `customer_id`.

The analysis found:

- Customers with delivered orders: **93,358**
- Repeat customers: **2,801**
- Repeat customer rate: **3.00%**

This suggests customer retention represents an important opportunity for marketplace improvement.

## Key Findings

### 1. Strong Marketplace Growth

The marketplace generated **$13.22 million in product GMV** across **96,478 delivered orders**, with an average order value of **$137.04**.

GMV grew substantially throughout 2017 and remained strong during 2018. November 2017 recorded the highest delivered-order volume with **7,289 orders**, while May 2018 generated the highest monthly GMV at **$977,544.69**.

### 2. Sales Are Concentrated in Major Product Categories

Health & Beauty generated the highest overall product GMV at approximately **$1.23 million**, followed by Watches & Gifts at **$1.17 million**.

Bed, Bath & Table had the highest delivered-order volume with **9,272 orders**.

Several established categories experienced substantial growth between January-August 2017 and January-August 2018, including:

- Health & Beauty: **+210.33%**
- Watches & Gifts: **+241.98%**
- Sports & Leisure: **+138.63%**
- Computers & Accessories: **+131.22%**
- Baby: **+268.56%**

Health & Beauty produced the largest absolute GMV increase among the analyzed categories, adding approximately **$512,203**.

### 3. Customer Retention Is Low

Only **2,801 of 93,358 customers** with delivered orders made more than one purchase.

This produced a repeat-customer rate of only **3.00%**, suggesting that customer retention represents a major opportunity for improvement.

### 4. GMV Is Geographically Concentrated

São Paulo generated approximately **$5.07 million in product GMV**, representing **38.33%** of total delivered-order GMV.

São Paulo, Rio de Janeiro, and Minas Gerais together accounted for approximately **63.38%** of total GMV.

This indicates that marketplace performance depends heavily on a relatively small number of states.

### 5. Late Delivery Is Strongly Associated With Lower Ratings

On-time deliveries received an average review score of **4.29**, compared with only **2.57** for late deliveries.

Late deliveries therefore received average ratings approximately **1.72 points lower**.

Several states also experienced particularly high late-delivery rates:

| State | Late Delivery Rate |
|---|---:|
| Alagoas (AL) | 23.93% |
| Maranhão (MA) | 19.67% |
| Piauí (PI) | 15.97% |
| Ceará (CE) | 15.32% |
| Sergipe (SE) | 15.22% |

### 6. Credit Cards Dominate Customer Payments

Credit cards represented **73.92% of payment records** and approximately **$12.54 million in payment value**.

Credit-card payments averaged **3.51 installments**, while the other major payment methods averaged approximately one installment.

### 7. Seller Sales Are Relatively Distributed

The highest-performing seller generated approximately **$226,988 in GMV**, representing only **1.72%** of total marketplace GMV.

The top 10 sellers together generated approximately **13.29%** of marketplace GMV.

This suggests that marketplace sales were distributed across many sellers rather than dominated by a small number of vendors.

## Business Recommendations

### Improve Customer Retention

With a repeat-customer rate of only **3.00%**, the marketplace should investigate strategies such as personalized promotions, post-purchase campaigns, loyalty incentives, and product recommendations designed to encourage customers to make additional purchases.

### Prioritize Delivery Performance

Because late deliveries were associated with significantly lower review scores, improving delivery reliability should be a major operational priority.

States with particularly high late-delivery rates, including Alagoas, Maranhão, Piauí, Ceará, and Rio de Janeiro, should receive additional logistics and fulfillment analysis.

### Support High-Growth Product Categories

High-growth categories such as Health & Beauty, Watches & Gifts, Baby, Sports & Leisure, Housewares, and Computers & Accessories may represent opportunities for additional promotional investment, seller recruitment, and inventory availability.

### Investigate Low-Satisfaction Categories

Office Furniture recorded the lowest average review score among categories with a meaningful number of reviewed orders.

Management should investigate whether product quality, seller performance, packaging, fulfillment, or delivery issues are contributing to lower satisfaction in this category.

### Reduce Geographic Dependence

Because São Paulo, Rio de Janeiro, and Minas Gerais account for a large share of marketplace GMV, the company should protect performance in these core markets while also evaluating opportunities to expand demand and improve logistics in less-developed regions.

## Conclusion

This analysis demonstrates how a raw multi-table e-commerce dataset can be transformed into a validated relational database and analyzed with SQL to support business decision-making.

The results highlight several actionable opportunities, particularly in customer retention, delivery performance, geographic expansion, and high-growth product categories. The project also demonstrates the use of PostgreSQL for data validation, relational database design, data cleaning, aggregation, CTEs, conditional logic, and window-function analysis.

## Repository Structure

```text
ecommerce-sql-analysis/
│
├── data/
│   └── raw/
│       └── Original Olist CSV datasets
│
├── sql/
│   ├── 01_database_setup.sql
│   ├── 02_data_validation.sql
│   ├── 03_geolocation_cleaning.sql
│   ├── 04_relationship_validation.sql
│   ├── 05_category_cleaning.sql
│   ├── 06_clean_database_build.sql
│   └── 07_business_analysis.sql
│
├── images/
│   └── Project screenshots and diagrams
│
├── data_dictionary.xlsx
├── findings_recommendations.md
└── README.md
```

### SQL File Guide

| File | Purpose |
|---|---|
| `01_database_setup.sql` | Creates the raw schema and staging tables used to import the original datasets |
| `02_data_validation.sql` | Profiles the source data and validates proposed primary and composite keys |
| `03_geolocation_cleaning.sql` | Cleans duplicate geographic records and creates one analytical record per ZIP-code prefix |
| `04_relationship_validation.sql` | Checks relationships between tables and identifies missing category translations |
| `05_category_cleaning.sql` | Creates the cleaned product-category lookup and standardized products table |
| `06_clean_database_build.sql` | Builds the remaining clean relational tables and performs final integrity checks |
| `07_business_analysis.sql` | Contains the 12 stakeholder-focused SQL business analyses |

## How to Reproduce the Project

### 1. Download the Dataset

Download the Brazilian E-Commerce Public Dataset by Olist from Kaggle.

The project uses the following nine source files:

- `olist_customers_dataset.csv`
- `olist_geolocation_dataset.csv`
- `olist_order_items_dataset.csv`
- `olist_order_payments_dataset.csv`
- `olist_order_reviews_dataset.csv`
- `olist_orders_dataset.csv`
- `olist_products_dataset.csv`
- `olist_sellers_dataset.csv`
- `product_category_name_translation.csv`

### 2. Create a PostgreSQL Database

Create a PostgreSQL database for the project.

Example:

```sql
CREATE DATABASE olist_ecommerce;
```

### 3. Run the Database Setup Script

Run:

```text
sql/01_database_setup.sql
```

This creates the raw staging tables.

### 4. Import the CSV Files

Import each Olist CSV file into its corresponding table in the `raw` schema.

### 5. Run the SQL Scripts in Order

Run the remaining scripts in the following sequence:

```text
02_data_validation.sql
03_geolocation_cleaning.sql
04_relationship_validation.sql
05_category_cleaning.sql
06_clean_database_build.sql
07_business_analysis.sql
```

The first six scripts prepare and validate the analytical database. The final script contains the stakeholder-focused business analysis.

## Dataset Notes

The original source data is preserved in the `raw` schema, while transformed data is stored separately in the `clean` schema. This approach preserves traceability and prevents the cleaning process from permanently overwriting the source records.

The geolocation dataset contains multiple observations for the same ZIP-code prefix. A separate analytical geography table was therefore created with one record per ZIP-code prefix using average coordinates and the most frequently occurring city/state combination.

Products with missing category information were retained and assigned to an `Unknown / Uncategorized` category rather than being removed.

## Author

**Ziyad Mohammed Ali**

MS in Management Information Systems  
University at Buffalo