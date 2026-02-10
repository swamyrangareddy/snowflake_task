-- Snowflake SQL Basics (Snowflake Intelligence context)
-- 0) Admin + Role bootstrap (run as ACCOUNTADMIN)

-- =========================================================
-- DAY-1 BASICS: Snowflake Intelligence style setup
-- (Role, Warehouse, Database/Schema, Table, Load, Grants)
-- =========================================================

-- 0.1) Use account-level admin privileges for setup
USE ROLE ACCOUNTADMIN;

-- 0.2) Create the admin role used by this use case (as in the quickstart)
CREATE OR REPLACE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;

-- 0.3) Give the role ability to create core objects (warehouse, database, integrations later)
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
GRANT CREATE DATABASE  ON ACCOUNT TO ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
--CREATE ALTER DELETE 
-- 0.4) Grant this role to your current user (so YOU can proceed without switching accounts)
SET CURRENT_USER = (SELECT CURRENT_USER());
GRANT ROLE SNOWFLAKE_INTELLIGENCE_ADMIN TO USER IDENTIFIER($CURRENT_USER);

-- (Optional teaching step) set defaults for your user for convenience
-- NOTE: Change default warehouse after we create it below, or re-run later.
-- ALTER USER IDENTIFIER($CURRENT_USER) SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_ADMIN;


-- 1) Create warehouse + database + schema (same names as quickstart)

-- Switch into the project admin role
USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;

-- 1.1) Warehouse for this project/use-case
CREATE OR REPLACE WAREHOUSE DASH_WH_SI
  WAREHOUSE_SIZE = 'XSMALL'      -- keep it small for training
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;

-- 1.2) Database and schema (retail use case)
CREATE OR REPLACE DATABASE DASH_DB_SI;
CREATE OR REPLACE SCHEMA DASH_DB_SI.RETAIL;

-- 1.3) Start using them
USE WAREHOUSE DASH_WH_SI;
USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;

-- Optional: set user defaults now that warehouse exists
SET CURRENT_USER = (SELECT CURRENT_USER());
ALTER USER IDENTIFIER($CURRENT_USER) SET DEFAULT_ROLE = SNOWFLAKE_INTELLIGENCE_ADMIN;
ALTER USER IDENTIFIER($CURRENT_USER) SET DEFAULT_WAREHOUSE = DASH_WH_SI;

---CREATE A NEW ROLE 

-- 2.1) Create a read-only training role for juniors
USE ROLE ACCOUNTADMIN;
CREATE OR REPLACE ROLE SI_TRAINING_STUDENT;

-- 2.2) Grant warehouse usage so they can run queries
GRANT USAGE ON WAREHOUSE DASH_WH_SI TO ROLE SI_TRAINING_STUDENT;

-- 2.3) Grant database + schema usage
GRANT USAGE ON DATABASE DASH_DB_SI TO ROLE SI_TRAINING_STUDENT;
GRANT USAGE ON SCHEMA DASH_DB_SI.RETAIL TO ROLE SI_TRAINING_STUDENT;

-- 2.4) Future grants: all future tables/views in this schema become readable automatically
GRANT SELECT ON FUTURE TABLES IN SCHEMA DASH_DB_SI.RETAIL TO ROLE SI_TRAINING_STUDENT;
GRANT SELECT ON FUTURE VIEWS  IN SCHEMA DASH_DB_SI.RETAIL TO ROLE SI_TRAINING_STUDENT;


-- 3.Create file format + external stage (S3) + load a table

-- Switch back to project admin role for object creation
USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
USE WAREHOUSE DASH_WH_SI;
USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;

-- 3.1) CSV file format (matches the quickstart style)
CREATE OR REPLACE FILE FORMAT SWT_CSVFORMAT
  TYPE = CSV
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- 3.2) Create an external stage pointing to Snowflake quickstart public bucket
-- This is a fast way to teach loading without managing your own files.
CREATE OR REPLACE STAGE SWT_MARKETING_DATA_STAGE
  FILE_FORMAT = SWT_CSVFORMAT
  URL = 's3://sfquickstarts/sfguide_getting_started_with_snowflake_intelligence/marketing/';

-- 3.3) Create a table (structured data)
CREATE OR REPLACE TABLE MARKETING_CAMPAIGN_METRICS (
  DATE          DATE,
  CATEGORY      STRING,
  CAMPAIGN_NAME STRING,
  IMPRESSIONS   NUMBER(38,0),
  CLICKS        NUMBER(38,0)
);

SELECT * FROM MARKETING_CAMPAIGN_METRICS;

-- 3.4) Load data from the stage into the table
COPY INTO MARKETING_CAMPAIGN_METRICS    ---table name
FROM @SWT_MARKETING_DATA_STAGE;

-- 3.5) Quick validation
SELECT COUNT(*) AS ROWS_LOADED FROM MARKETING_CAMPAIGN_METRICS;
SELECT * FROM MARKETING_CAMPAIGN_METRICS LIMIT 10;

USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;

-- Make sure students can read this existing table
GRANT SELECT ON TABLE DASH_DB_SI.RETAIL.MARKETING_CAMPAIGN_METRICS TO ROLE SI_TRAINING_STUDENT;


-- 5) SQL basics practice queries (SELECT, WHERE, GROUP BY, ORDER BY)

-- Run these as SI_TRAINING_STUDENT (for demo) or as admin
USE ROLE SNOWFLAKE_INTELLIGENCE_ADMIN;
USE WAREHOUSE DASH_WH_SI;
USE DATABASE DASH_DB_SI;
USE SCHEMA RETAIL;

-- 5.1) Filter
SELECT *
FROM MARKETING_CAMPAIGN_METRICS
WHERE IMPRESSIONS>10000;


-- 5.2) Add calculated column (CTR = clicks / impressions)
SELECT
  DATE,
  CATEGORY,
  CAMPAIGN_NAME,
  IMPRESSIONS,
  CLICKS,
  (CLICKS / NULLIF(IMPRESSIONS,0)) AS CTR
FROM MARKETING_CAMPAIGN_METRICS
ORDER BY DATE DESC
LIMIT 50;

-- 5.3) Aggregate trend
SELECT
  DATE,
  SUM(IMPRESSIONS) AS TOTAL_IMPRESSIONS,
  SUM(CLICKS)      AS TOTAL_CLICKS
FROM MARKETING_CAMPAIGN_METRICS
GROUP BY DATE
ORDER BY DATE;

-- 5.4) Top campaigns by clicks
SELECT
  CAMPAIGN_NAME,
  SUM(CLICKS) AS TOTAL_CLICKS
FROM MARKETING_CAMPAIGN_METRICS
GROUP BY CAMPAIGN_NAME
ORDER BY TOTAL_CLICKS DESC
LIMIT 10;


----- create a 4 table with sales
---20 sql questions

-- Table 1: products
CREATE OR REPLACE TABLE PRODUCTS (
    product_id number,
    product_name STRING,
    category STRING
);

COPY INTO PRODUCTS    
FROM @SWT_MARKETING_DATA_STAGE;

-- Table 2: social_media_mentions
CREATE OR REPLACE TABLE social_media_mentions (
    date DATE,
    category STRING,
    platform STRING,
    influencer STRING,
    mentions INT
);

-- Table 3: support_cases
CREATE OR REPLACE TABLE support_cases (
    id STRING, -- Using string for UUID/Hash format
    title STRING,
    product STRING,
    transcript STRING,
    date DATE
);

-- Table 4: Sales Table
--  Product Table ---
CREATE OR REPLACE TABLE SALES (
    DATE DATE,
    region string,
    product_id number,
    units_sold number,
    sales_amount number
);

COPY INTO SUPPORT_CASES    
FROM @SWT_MARKETING_DATA_STAGE;

-- total table data view

SELECT * FROM SALES;

SELECT * From PRODUCTS;

SELECT * FROM SOCIAL_MEDIA_MENTIONS;

SELECT * FROM SUPPORT_CASES;

-- specific region sales

ALTER SESSION SET DATE_INPUT_FORMAT = 'DD-MM-YYYY';


SELECT 
    campaign_name, 
    SUM(clicks) AS total_clicks
FROM marketing_campaign_metrics
GROUP BY 1
ORDER BY total_clicks DESC
LIMIT 10;

SELECT 
    date, 
    category, 
    campaign_name, 
    impressions, 
    clicks,
    -- DIV0 returns 0 if the divisor is 0
    DIV0(clicks, impressions) AS ctr
    -- Alternatively, using NULLIF to return NULL on zero:
    -- (clicks / NULLIF(impressions, 0)) AS ctr_null_safe
FROM marketing_campaign_metrics;

SELECT 
    date, 
    SUM(sales_amount) AS total_sales_amount, 
    SUM(units_sold) AS total_units_sold
FROM sales
GROUP BY date
ORDER BY date DESC;

SELECT 
    region, 
    SUM(sales_amount) AS total_sales_amount
FROM sales
GROUP BY region
ORDER BY total_sales_amount DESC
LIMIT 1;

SELECT 
    product_id, 
    product_name, 
    category
FROM products
WHERE category = 'Fitness Wear' -- we can replace this with any category
ORDER BY product_name ASC;

---  Intermediate 

SELECT 
    s.date, 
    s.region, 
    p.product_name, 
    p.category, 
    s.units_sold, 
    s.sales_amount
FROM SALES s
JOIN PRODUCTS p ON s.PRODUCT_ID = p.PRODUCT_ID;

SELECT 
    p.category, 
    s.region, 
    SUM(s.sales_amount) AS total_sales_amount
FROM sales s
JOIN products p ON s.PRODUCT_ID = p.PRODUCT_ID
GROUP BY 1, 2
ORDER BY total_sales_amount DESC;

SELECT 
    region, 
    product_name, 
    SUM(sales_amount) AS total_sales
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY 1, 2
QUALIFY ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_sales DESC) = 1;

SELECT 
    date, 
    category, 
    SUM(impressions) AS total_impressions, 
    SUM(clicks) AS total_clicks,
    DIV0(SUM(clicks), SUM(impressions)) AS ctr
FROM marketing_campaign_metrics
GROUP BY 1, 2
ORDER BY date, category;

SELECT 
    platform, 
    SUM(mentions) AS platform_mentions,
    SUM(mentions) / SUM(SUM(mentions)) OVER () AS percent_share
FROM social_media_mentions
GROUP BY platform;

SELECT 
    platform, 
    influencer, 
    SUM(mentions) AS total_mentions
FROM social_media_mentions
GROUP BY 1, 2
QUALIFY DENSE_RANK() OVER (PARTITION BY platform ORDER BY total_mentions DESC) <= 3;

SELECT 
    m.date, 
    m.category, 
    SUM(m.clicks) AS total_clicks, 
    SUM(m.impressions) AS total_impressions, 
    SUM(s.mentions) AS total_mentions
FROM marketing_campaign_metrics m
JOIN social_media_mentions s 
    ON m.date = s.date 
    AND m.category = s.category
GROUP BY 1, 2;

SELECT 
    product, 
    COUNT(id) AS case_count
FROM support_cases
GROUP BY 1
ORDER BY case_count DESC
LIMIT 10;

---- Advanced 

SELECT 
    date,
    region,
    SUM(sales_amount) AS daily_sales,
    SUM(SUM(sales_amount)) OVER (
        PARTITION BY region 
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_sales
FROM sales
GROUP BY 1, 2;

WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('MONTH', date) AS sales_month,
        region,
        SUM(sales_amount) AS total_sales
    FROM sales
    GROUP BY 1, 2
)
SELECT 
    sales_month,
    region,
    total_sales,
    LAG(total_sales) OVER (PARTITION BY region ORDER BY sales_month) AS prev_month_sales,
    DIV0(total_sales - prev_month_sales, prev_month_sales) * 100 AS mom_growth_pct
FROM monthly_sales;

SELECT 
    category,
    campaign_name,
    SUM(impressions) AS total_impressions,
    DIV0(SUM(clicks), SUM(impressions)) AS ctr
FROM marketing_campaign_metrics
GROUP BY 1, 2
HAVING total_impressions >= 10000
QUALIFY ROW_NUMBER() OVER (PARTITION BY category ORDER BY ctr DESC) <= 5;

SELECT * FROM (
    SELECT date, region, sales_amount 
    FROM sales
)
PIVOT (SUM(sales_amount) FOR region IN ('North', 'South', 'East', 'West', 'International'))
ORDER BY date;

--------
WITH stats AS (
    SELECT 
        date,
        region,
        sales_amount,
        AVG(sales_amount) OVER (PARTITION BY region) AS avg_sales,
        STDDEV(sales_amount) OVER (PARTITION BY region) AS std_sales
    FROM sales
)
SELECT *,
    CASE 
        WHEN sales_amount > (avg_sales + 2 * std_sales) THEN 'Unusually High'
        WHEN sales_amount < (avg_sales - 2 * std_sales) THEN 'Unusually Low'
    END AS flag_reason
FROM stats
QUALIFY flag_reason IS NOT NULL;



CREATE OR REPLACE VIEW RETAIL_DAILY_KPIS_VW AS
WITH sales_agg AS (
    SELECT 
        s.date, 
        p.category, 
        SUM(s.sales_amount) AS total_sales,
        SUM(s.units_sold) AS total_units
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    GROUP BY 1, 2
),
mkt_agg AS (
    SELECT 
        date, 
        category, 
        SUM(clicks) AS total_clicks,
        SUM(impressions) AS total_impressions
    FROM marketing_campaign_metrics
    GROUP BY 1, 2
),
soc_agg AS (
    SELECT 
        date, 
        category, 
        SUM(mentions) AS total_mentions
    FROM social_media_mentions
    GROUP BY 1, 2
)
SELECT 
    COALESCE(sa.date, ma.date, so.date) AS date,
    COALESCE(sa.category, ma.category, so.category) AS category,
    -- Sales Metrics
    NVL(sa.total_sales, 0) AS daily_revenue,
    NVL(sa.total_units, 0) AS units_sold,
    -- Marketing Metrics
    NVL(ma.total_clicks, 0) AS marketing_clicks,
    NVL(ma.total_impressions, 0) AS marketing_impressions,
    DIV0(NVL(ma.total_clicks, 0), NVL(ma.total_impressions, 0)) AS ctr,
    -- Social Metrics
    NVL(so.total_mentions, 0) AS social_mentions
FROM sales_agg sa
FULL OUTER JOIN mkt_agg ma ON sa.date = ma.date AND sa.category = ma.category
FULL OUTER JOIN soc_agg so ON COALESCE(sa.date, ma.date) = so.date 
                          AND COALESCE(sa.category, ma.category) = so.category;
