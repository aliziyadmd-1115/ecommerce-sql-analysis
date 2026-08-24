-- ============================================================
-- OLIST E-COMMERCE DATA ANALYSIS
-- 03_geolocation_cleaning.sql
--
-- Purpose:
-- Transform the raw Olist geolocation data into a ZIP-level
-- geography table that can be safely joined to customers
-- and sellers without multiplying transactional records.
--
-- Raw geolocation rows:      1,000,163
-- Distinct ZIP prefixes:        19,015
-- Clean geolocation rows:       19,015
--
-- The original raw geolocation table remains unchanged.
-- ============================================================


-- ============================================================
-- 1. CREATE CLEAN SCHEMA
-- ============================================================

CREATE SCHEMA IF NOT EXISTS clean;


-- ============================================================
-- 2. CREATE CLEAN GEOLOCATION TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS clean.geolocation (
    geolocation_id BIGINT
        GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    geolocation_zip_code_prefix VARCHAR(5)
        NOT NULL UNIQUE,

    geolocation_lat NUMERIC(10,6),

    geolocation_lng NUMERIC(10,6),

    geolocation_city VARCHAR(100),

    geolocation_state VARCHAR(2)
);


-- ============================================================
-- 3. CLEAN AND SUMMARIZE GEOLOCATION
-- ============================================================
--
-- Cleaning decisions:
--
-- 1. raw.geolocation remains unchanged.
--
-- 2. One analytical record is created per ZIP prefix.
--
-- 3. Average latitude and longitude provide representative
--    coordinates for each ZIP prefix.
--
-- 4. The most frequently occurring city/state combination is
--    selected for each ZIP prefix.
--
-- 5. ROW_NUMBER() resolves city/state conflicts.
--
-- 6. ON CONFLICT makes this transformation safe to rerun.
-- ============================================================

WITH normalized AS (

    SELECT
        TRIM(geolocation_zip_code_prefix) AS zip_code_prefix,

        NULLIF(TRIM(geolocation_lat), '')::NUMERIC
            AS latitude,

        NULLIF(TRIM(geolocation_lng), '')::NUMERIC
            AS longitude,

        LOWER(TRIM(geolocation_city))
            AS city,

        UPPER(TRIM(geolocation_state))
            AS state

    FROM raw.geolocation

    WHERE NULLIF(
        TRIM(geolocation_zip_code_prefix),
        ''
    ) IS NOT NULL
),

coordinate_summary AS (

    SELECT
        zip_code_prefix,

        ROUND(
            AVG(latitude),
            6
        ) AS average_latitude,

        ROUND(
            AVG(longitude),
            6
        ) AS average_longitude

    FROM normalized

    GROUP BY zip_code_prefix
),

location_counts AS (

    SELECT
        zip_code_prefix,
        city,
        state,
        COUNT(*) AS occurrence_count

    FROM normalized

    GROUP BY
        zip_code_prefix,
        city,
        state
),

ranked_locations AS (

    SELECT
        zip_code_prefix,
        city,
        state,
        occurrence_count,

        ROW_NUMBER() OVER (
            PARTITION BY zip_code_prefix
            ORDER BY
                occurrence_count DESC,
                state,
                city
        ) AS location_rank

    FROM location_counts
)

INSERT INTO clean.geolocation (
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)

SELECT
    c.zip_code_prefix,
    c.average_latitude,
    c.average_longitude,
    l.city,
    l.state

FROM coordinate_summary c

JOIN ranked_locations l
    ON c.zip_code_prefix = l.zip_code_prefix

WHERE l.location_rank = 1

ON CONFLICT (geolocation_zip_code_prefix)
DO UPDATE SET
    geolocation_lat = EXCLUDED.geolocation_lat,
    geolocation_lng = EXCLUDED.geolocation_lng,
    geolocation_city = EXCLUDED.geolocation_city,
    geolocation_state = EXCLUDED.geolocation_state;


-- ============================================================
-- 4. VALIDATE TOTAL ROWS VS UNIQUE ZIP PREFIXES
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS unique_zip_prefixes
FROM clean.geolocation;

-- Observed result:
-- total_rows = 19,015
-- unique_zip_prefixes = 19,015



-- ============================================================
-- 5. CHECK FOR DUPLICATE ZIP PREFIXES
-- ============================================================

SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS record_count
FROM clean.geolocation
GROUP BY geolocation_zip_code_prefix
HAVING COUNT(*) > 1;

-- Observed result: 0 rows



-- ============================================================
-- 6. VALIDATE SURROGATE PRIMARY KEY
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_id) AS unique_ids
FROM clean.geolocation;

-- Observed result:
-- total_rows = 19,015
-- unique_ids = 19,015



-- ============================================================
-- 7. CHECK FOR NULL ZIP PREFIXES
-- ============================================================

SELECT COUNT(*) AS missing_zip_prefixes
FROM clean.geolocation
WHERE geolocation_zip_code_prefix IS NULL;

-- Observed result: 0



-- ============================================================
-- 8. CHECK FOR MISSING COORDINATES
-- ============================================================

SELECT COUNT(*) AS missing_coordinates
FROM clean.geolocation
WHERE geolocation_lat IS NULL
   OR geolocation_lng IS NULL;

-- Observed result: 0



-- ============================================================
-- 9. SAMPLE CLEANED GEOLOCATION DATA
-- ============================================================

SELECT *
FROM clean.geolocation
ORDER BY geolocation_zip_code_prefix
LIMIT 20;


-- ============================================================
-- CLEANING SUMMARY
-- ============================================================
--
-- raw.geolocation:
--     1,000,163 original geographic observations
--
-- clean.geolocation:
--     19,015 ZIP-level analytical records
--
-- Clean table:
--     Uses a surrogate geolocation_id PK
--     Enforces one row per ZIP prefix
--     Contains no duplicate ZIP prefixes
--     Contains no NULL ZIP prefixes
--     Contains no missing coordinates
--
-- No source data was modified or deleted.
-- ============================================================