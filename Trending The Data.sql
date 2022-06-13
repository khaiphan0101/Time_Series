
/* Exercise 1: SIMPLE TREND
Task: You need to analyze the trend of payment transactions of Billing category from 2019 to 2020. First, let’s show the trend of the number of successful transaction by month. */ 

WITH fact_table AS (
SELECT *
FROM fact_transaction_2019 
UNION 
SELECT *
FROM fact_transaction_2020 ) 
SELECT 
    CONVERT(nvarchar(6), transaction_time, 112) AS month
    , COUNT(transaction_id) AS number_trans
FROM fact_table 
JOIN dim_scenario AS sce ON fact_table.scenario_id = sce.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY CONVERT(nvarchar(6), transaction_time, 112)
ORDER BY month

/* Exercise 2: COMPARING COMPONENT
You know that, there are many sub-categories of Billing group. After reviewing the above result, you should break down the trend into each sub-categories.*/

WITH fact_table AS (
SELECT *
FROM fact_transaction_2019 
UNION 
SELECT *
FROM fact_transaction_2020 )
SELECT 
    YEAR(transaction_time) AS year, MONTH(transaction_time) AS month
    , sub_category
    , COUNT(transaction_id) AS number_trans
FROM fact_table 
JOIN dim_scenario AS sce ON fact_table.scenario_id = sce.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category
ORDER BY year, month 

-- Then modify the result as the following table: Only select the sub-categories belong to list (Electricity, Internet and Water)

WITH fact_table AS (
SELECT *
FROM fact_transaction_2019 
UNION 
SELECT *
FROM fact_transaction_2020 )
, sub_count AS (
SELECT 
    YEAR(transaction_time) AS year, MONTH(transaction_time) AS month
    , sub_category
    , COUNT(transaction_id) AS number_trans
FROM fact_table 
JOIN dim_scenario AS sce ON fact_table.scenario_id = sce.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category
)
SELECT 
    year, month 
    , SUM( CASE 
        WHEN sub_category = 'Electricity' THEN number_trans END) AS electricity_trans
    , SUM( CASE 
        WHEN sub_category = 'Internet' THEN number_trans END) AS internet_trans
    , SUM( CASE 
        WHEN sub_category = 'Water' THEN number_trans END) AS water_trans
FROM sub_count
GROUP BY year, month
ORDER BY year, month

-- #2: PIVOT TABLE 

WITH fact_table AS (
SELECT *
FROM fact_transaction_2019 
UNION 
SELECT *
FROM fact_transaction_2020 )
, sub_count AS (
SELECT 
    YEAR(transaction_time) AS year, MONTH(transaction_time) AS month
    , sub_category
    , COUNT(transaction_id) AS number_trans
FROM fact_table 
JOIN dim_scenario AS sce ON fact_table.scenario_id = sce.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category
)
SELECT
    year 
    , month 
    , "Electricity" AS electricity_trans
    , "Internet" AS internet_trans
    , "Water" AS water_trans
FROM ( SELECT * 
    FROM sub_count) AS source_table 
PIVOT (
    SUM(number_trans)
    FOR sub_category IN ("Electricity", "Internet", "Water")
) AS pivot_table

/* Exercise 3: Percent of Total Calculations 
Based on the previous query, you need to calculate the proportion of each sub-category (Electricity, Internet and Water) in the total for each month. */

WITH fact_table AS (
SELECT *
FROM fact_transaction_2019 
UNION 
SELECT *
FROM fact_transaction_2020 )
, sub_count AS (
SELECT 
    YEAR(transaction_time) year, MONTH(transaction_time) month
    , sub_category
    , COUNT(transaction_id) AS number_trans
FROM fact_table 
JOIN dim_scenario AS sce ON fact_table.scenario_id = sce.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category
)
, sub_count_1 AS (
SELECT 
    year, month 
    , SUM( CASE 
        WHEN sub_category = 'Electricity' THEN number_trans END) AS electricity_trans
    , SUM( CASE 
        WHEN sub_category = 'Internet' THEN number_trans END) AS internet_trans
    , SUM( CASE 
        WHEN sub_category = 'Water' THEN number_trans END) AS water_trans
FROM sub_count
GROUP BY year, month
)
SELECT * 
    , ISNULL(electricity_trans,0) + ISNULL(internet_trans,0) + ISNULL(water_trans,0) AS total_trans_month
    , FORMAT(1.0*ISNULL(electricity_trans,0)/(ISNULL(electricity_trans,0) + ISNULL(internet_trans,0) + ISNULL(water_trans,0)), 'p') AS elec_pct
    , FORMAT(1.0*ISNULL(internet_trans,0)/(ISNULL(electricity_trans,0) +  ISNULL(internet_trans,0) + ISNULL(water_trans,0)), 'p') AS internet_pct
    , FORMAT(1.0*ISNULL(water_trans,0)/(ISNULL(electricity_trans,0) + ISNULL(internet_trans,0) + ISNULL(water_trans,0)), 'p') AS water_pct
FROM sub_count_1

/* Exercise 4: Indexing to See Percent Change over Time
Task: Select only these sub-categories in the list (Electricity, Internet and Water), you need to calculate the number of successful paying customers for each month (from 2019 to 2020). 
Then find the percentage change from the first month (Jan 2019) for each subsequent month. */

WITH fact_table AS (
SELECT * FROM fact_transaction_2019
UNION 
SELECT * FROM fact_transaction_2020
)
, fact_table_1 AS (
SELECT MONTH(transaction_time) month, YEAR(transaction_time) year
    , COUNT( DISTINCT customer_id ) AS number_customer
FROM fact_table
JOIN dim_scenario AS scena ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Billing' AND status_id = 1 AND sub_category IN ('Electricity', 'Internet',  'Water')
GROUP BY MONTH(transaction_time), YEAR(transaction_time)
)
SELECT *
    , FIRST_VALUE(number_customer) OVER(ORDER BY year, month) AS starting_point
    , FORMAT(1.0*number_customer/FIRST_VALUE(number_customer) OVER(ORDER BY year, month) - 1,  'p') AS pct_change
FROM fact_table_1 
ORDER BY year, month
