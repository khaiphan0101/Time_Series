
/* Exercise 1:
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



-- 1.2 
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

-- Modify result : 
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

-- cách 2: PIVOT TABLE 

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

-- 1.3 Percent of total 
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

-- 1.4 

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


SELECT *
    , FIRST_VALUE(number_customer) OVER (ORDER BY year, month ) AS staring_point
    , FORMAT((1.0* number_customer) / FIRST_VALUE(number_customer) OVER (ORDER BY year, month ) - 1.0, 'p') AS pct_from_staring_point
FROM fact_table_1

-- 2. Rolling time window

/* 2.1 Task: Select only these sub-categories in the list (Electricity, Internet and Water), 
you need to calculate the number of successful paying customers for each week number from 2019 to 2020). 
Then get rolling annual paying users of total. */ 

select datepart(week, '2022-04-20');

WITH fact_table AS (
SELECT * FROM fact_transaction_2019
UNION 
SELECT * FROM fact_transaction_2020
)
, fact_table_1 AS (
SELECT YEAR(transaction_time) year, DATEPART(week, transaction_time) AS week_number
    , CONCAT(YEAR(transaction_time), DATEPART(week, transaction_time)) AS calendar
    , COUNT( DISTINCT customer_id ) AS number_customer
FROM fact_table
JOIN dim_scenario AS scena ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Billing' AND status_id = 1 AND sub_category IN ('Electricity', 'Internet',  'Water')
GROUP BY YEAR(transaction_time), DATEPART(week, transaction_time)
-- ORDER BY year, week_number
)
SELECT *
    , SUM(number_customer) OVER (PARTITION BY year ORDER BY week_number ASC ) AS rolling_number
FROM fact_table_1
ORDER BY year, week_number

/* 2.2 Task: Based on the previous query, calculate the average number of customers 
for the last 4 weeks in each observation week. 
Then compare the difference between the current value and the average value of the last 4 weeks. */ 

WITH fact_table AS (
SELECT * FROM fact_transaction_2019
UNION 
SELECT * FROM fact_transaction_2020
)
, fact_table_1 AS (
SELECT YEAR(transaction_time) year, DATEPART(week, transaction_time) AS week_number
    , CONCAT(YEAR(transaction_time), DATEPART(week, transaction_time)) AS calendar
    , COUNT( DISTINCT customer_id ) AS number_customer
FROM fact_table
JOIN dim_scenario AS scena ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Billing' AND status_id = 1 AND sub_category IN ('Electricity', 'Internet',  'Water')
GROUP BY YEAR(transaction_time), DATEPART(week, transaction_time)
)
SELECT *
    , AVG(number_customer) OVER ( ORDER BY year ASC, week_number ASC
                            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS avg_last_4weeks
FROM fact_table_1

/* 3. Task: Based on the query 2.1, calculate the growth rate of the number of users by month compared 
to the same period last year. */ 

WITH fact_table AS (
SELECT * FROM fact_transaction_2019
UNION 
SELECT * FROM fact_transaction_2020
)
, fact_table_1 AS (
SELECT YEAR(transaction_time) year,  MONTH(transaction_time) AS month
    , CONCAT(YEAR(transaction_time), MONTH(transaction_time)) AS calendar
    , COUNT( DISTINCT customer_id ) AS number_customer
FROM fact_table
JOIN dim_scenario AS scena ON fact_table.scenario_id = scena.scenario_id
WHERE category = 'Billing' AND status_id = 1 AND sub_category IN ('Electricity', 'Internet',  'Water')
GROUP BY YEAR(transaction_time), MONTH(transaction_time)
)
SELECT *
    , LAG(number_customer, 12, number_customer) OVER (ORDER BY year, MONTH ) AS last_period
    , FORMAT(1.0*number_customer/(LAG(number_customer, 12, number_customer) OVER (ORDER BY year, MONTH )), 'p') AS MOM
FROM fact_table_1
ORDER BY year, month

-- Tạo bảng tạm ở local 

SELECT *
INTO #table_b -- new table at local 
FROM table_a

WITH fact_table AS (
SELECT *
FROM fact_transaction_2019 
UNION 
SELECT *
FROM fact_transaction_2020 )

SELECT 
    YEAR(transaction_time) year, MONTH(transaction_time) month
    , sub_category
    , COUNT(transaction_id) AS number_trans
INTO #sub_count_table
FROM fact_table 
JOIN dim_scenario AS sce ON fact_table.scenario_id = sce.scenario_id
WHERE status_id = 1 AND category = 'Billing'
GROUP BY YEAR(transaction_time), MONTH(transaction_time), sub_category


SELECT * 
FROM #sub_count_table

-- Tạo bảng tạm ở global  
-- ##new_table 




