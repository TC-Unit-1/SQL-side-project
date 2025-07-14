/* 
All data cleansing process is done on Google Big Query 
All visulizationn iss done on Power BI
Data are extracted from Kaggle (https://www.kaggle.com/datasets/ihelon/coffee-sales)
Data cover from 1/3/2024 - 23/3/2025
*/

/* Task 1: Calculate the average order value. Result in [AVG order value] */ 
SELECT 
  ROUND(SUM(money) / COUNT(*),2) AVG_order_value
FROM `Coffee_shop.Sales data`;

/* Task 2: Find out the least favourable product. Result in [Bottom seller] */
SELECT 
  DISTINCT coffee_name, 
  COUNT(*) Sales_quantity
FROM `Coffee_shop.Sales data`
GROUP BY coffee_name 
ORDER BY Sales_quantity
LIMIT 3;

/* Task 3: Calculate the sales quantity in different hour. Result in [Hourly trend of sales quantity] */
/* To extract all possible working hour */
WITH cte AS (
  SELECT 
    DISTINCT EXTRACT( HOUR FROM datetime) Hour,
  FROM `Coffee_shop.Sales data`
  ORDER BY Hour
)
/* Combine all possible working hour with the corresponding sales quantity */
SELECT 
  HOUR,
  IFNULL(Sales_quantity,0) Sales_quantity
FROM cte 
LEFT JOIN (
  SELECT 
    DISTINCT EXTRACT( HOUR FROM datetime) Hour,
    COUNT(*) Sales_quantity
  FROM `Coffee_shop.Sales data`
  GROUP BY Hour
) USING(Hour)
ORDER BY HOUR;

/* Task 4: Calculate the sales quantity of various products in different hour. Result in [Hourly trend of sales quantity - Individual product] */
/* Extract all possible combination between working hour and coffee type */
WITH cte AS (
  SELECT 
    DISTINCT s2.coffee_name,
    EXTRACT( HOUR FROM datetime) Hour,
  FROM `Coffee_shop.Sales data` s1
  CROSS JOIN (SELECT DISTINCT coffee_name FROM  `Coffee_shop.Sales data`) s2
  ORDER BY Hour
)
/* Combine cte with it's corresponding sales quantity */
SELECT 
  coffee_name, 
  Hour, 
  IFNULL(Sales_amount,0) Sales_quantity
FROM cte
LEFT JOIN (
  SELECT 
    DISTINCT coffee_name, 
    EXTRACT( HOUR FROM datetime) Hour,
    COUNT(*) Sales_amount
  FROM `Coffee_shop.Sales data`
  GROUP BY coffee_name, Hour
) USING(coffee_name, Hour)
ORDER BY Hour;

/* Task 5: Calculate the sales revenue in different hour. Result in [Hourly trend of sales revenue] */
/* Extract all possible working hour */
WITH cte AS (
  SELECT 
    DISTINCT EXTRACT( HOUR FROM datetime) Hour,
  FROM `Coffee_shop.Sales data`
  ORDER BY Hour
)
/* Combine all possible working hour with the corresponding sales revenue */
SELECT 
  HOUR,
  ROUND(IFNULL(Sales_Revenue,0),2) Sales_revenue
FROM cte 
LEFT JOIN (
  SELECT 
    DISTINCT EXTRACT( HOUR FROM datetime) Hour,
    SUM(money) Sales_revenue
  FROM `Coffee_shop.Sales data`
  GROUP BY Hour
) USING(Hour)
ORDER BY HOUR;

/* Task 6: Calculate the sales revenue of various products in different hour. Result in [Hourly trend of sales revenue - Individual product] */
/* Extract all possible combination between working hour and coffee type */
WITH cte AS (
  SELECT 
    DISTINCT s2.coffee_name,
    EXTRACT( HOUR FROM datetime) Hour,
  FROM `Coffee_shop.Sales data` s1
  CROSS JOIN (SELECT DISTINCT coffee_name FROM  `Coffee_shop.Sales data`) s2
  ORDER BY Hour
)
/* Combine cte with it's corresponding sales revenue */
SELECT 
  coffee_name, 
  Hour, 
  IFNULL(Sales_revenue,0) Sales_revenue
FROM cte
LEFT JOIN (
  SELECT 
    DISTINCT coffee_name, 
    EXTRACT( HOUR FROM datetime) Hour,
    ROUND(SUM(money),2) Sales_revenue
  FROM `Coffee_shop.Sales data`
  GROUP BY coffee_name, Hour
) USING(coffee_name, Hour)
ORDER BY Hour;

/* Task 7: Summarize the payment method used by customer. Result in [Payment method] */
SELECT 
  DISTINCT cash_type, 
  COUNT(*) Payment_count
FROM `Coffee_shop.Sales data`
GROUP BY cash_type;

/* Task 8: Summerize the sales quantity of different products. Result in [Sales quantity by coffee category] */
SELECT 
  DISTINCT coffee_name, 
  COUNT(*) Sales_quantity
FROM `Coffee_shop.Sales data`
GROUP BY coffee_name;

/* Task 9: Find out the most favourable product. Result in [Top seller] */
SELECT 
  DISTINCT coffee_name, 
  COUNT(*) Sales_quantity
FROM `Coffee_shop.Sales data`
GROUP BY coffee_name 
ORDER BY Sales_quantity DESC
LIMIT 3;

/* Task 10: Calculate the total coffee sold. Result in [Total coffee sold] */
SELECT 
  COUNT(*) Total_coffee_sold
FROM `Coffee_shop.Sales data`;

/* Task 11: Calculate the total revenue. Results in [Total revenue] */
SELECT   
  ROUND(SUM(money),2) Total_revenue
FROM `coffee-shop-464201.Coffee_shop.Sales data` ;

/* Task 12: Calculate the sales quantity in different day of week. Result in [Weekly trend of sales quantity] */
/* Extract date in the format of weekday name and assign each weekday a number for ranking */
WITH cte AS (
  SELECT 
    DISTINCT FORMAT_DATE('%a', date) Week_day,
  FROM `Coffee_shop.Sales data` 
), 
cte2 AS(
  SELECT 
    Week_day,
    CASE 
      WHEN Week_day = 'Mon' THEN 1
      WHEN Week_day = 'Tue' THEN 2
      WHEN Week_day = 'Wed' THEN 3
      WHEN Week_day = 'Thu' THEN 4
      WHEN Week_day = 'Fri' THEN 5
      WHEN Week_day = 'Sat' THEN 6
      WHEN Week_day = 'Sun' THEN 7
      ELSE 0
    End r
  FROM cte
)

SELECT 
  Week_day, 
  IFNULL(Sales_amount,0) Sales_quantity
FROM cte2
LEFT JOIN (
  SELECT 
    FORMAT_DATE('%a', date) Week_day,
    COUNT(*) Sales_amount
  FROM `Coffee_shop.Sales data`
  GROUP BY FORMAT_DATE('%a', date)
) USING(Week_day)
ORDER BY r;

/* Task 13: Calculate the sales quantity of different products in different day of week. Result in [Weekly trend of sales quantity - Individual product] */
/* Extract date in the format of weekday name and assign each weekday a number for ranking */
WITH cte AS (
  SELECT 
    DISTINCT s2.coffee_name,
    FORMAT_DATE('%a', date) Week_day,
  FROM `Coffee_shop.Sales data` s1
  CROSS JOIN (SELECT DISTINCT coffee_name FROM  `Coffee_shop.Sales data`) s2
),
cte2 AS(
  SELECT 
    coffee_name,
    Week_day,
    CASE 
      WHEN Week_day = 'Mon' THEN 1
      WHEN Week_day = 'Tue' THEN 2
      WHEN Week_day = 'Wed' THEN 3
      WHEN Week_day = 'Thu' THEN 4
      WHEN Week_day = 'Fri' THEN 5
      WHEN Week_day = 'Sat' THEN 6
      WHEN Week_day = 'Sun' THEN 7
      ELSE 0
    End r
  FROM cte
)

SELECT 
  coffee_name, 
  Week_day, 
  IFNULL(Sales_amount,0) Sales_quantity
FROM cte2
LEFT JOIN (
  SELECT 
    DISTINCT coffee_name, 
    FORMAT_DATE('%a', date) Week_day,
    COUNT(*) Sales_amount
  FROM `Coffee_shop.Sales data`
  GROUP BY coffee_name, FORMAT_DATE('%a', date)
) USING(coffee_name, Week_day)
ORDER BY r;

/* Task 14: Calculate the sales revenue in different day of week. Result in [Weekly trend of sales quantity - Individual product] */
/* Extract date in the format of weekday name and assign each weekday a number for ranking */
WITH cte AS (
  SELECT 
    DISTINCT FORMAT_DATE('%a', date) Week_day,
  FROM `Coffee_shop.Sales data` 
),
cte2 AS(
  SELECT 
    Week_day,
    CASE 
      WHEN Week_day = 'Mon' THEN 1
      WHEN Week_day = 'Tue' THEN 2
      WHEN Week_day = 'Wed' THEN 3
      WHEN Week_day = 'Thu' THEN 4
      WHEN Week_day = 'Fri' THEN 5
      WHEN Week_day = 'Sat' THEN 6
      WHEN Week_day = 'Sun' THEN 7
      ELSE 0
    End r
  FROM cte
)


SELECT 
  Week_day, 
  ROUND(IFNULL(Sales_revenue,0),2) Sales_revenue
FROM cte2
LEFT JOIN (
  SELECT 
    FORMAT_DATE('%a', date) Week_day,
    SUM(money) Sales_revenue
  FROM `Coffee_shop.Sales data`
  GROUP BY FORMAT_DATE('%a', date)
) USING(Week_day)
ORDER BY r;

/* Task 15: Calculate the sales revenue of different products in different day of week. Result in [Weekly trend of sales revenue - Individual product] */
/* Extract date in the format of weekday name and assign each weekday a number for ranking */
WITH cte AS (
  SELECT 
    DISTINCT s2.coffee_name,
    FORMAT_DATE('%a', date) Week_day,
  FROM `Coffee_shop.Sales data` s1
  CROSS JOIN (SELECT DISTINCT coffee_name FROM  `Coffee_shop.Sales data`) s2
),
cte2 AS(
  SELECT 
    coffee_name,
    Week_day,
    CASE 
      WHEN Week_day = 'Mon' THEN 1
      WHEN Week_day = 'Tue' THEN 2
      WHEN Week_day = 'Wed' THEN 3
      WHEN Week_day = 'Thu' THEN 4
      WHEN Week_day = 'Fri' THEN 5
      WHEN Week_day = 'Sat' THEN 6
      WHEN Week_day = 'Sun' THEN 7
      ELSE 0
    End r
  FROM cte
)

SELECT 
  coffee_name, 
  Week_day, 
  IFNULL(Sales_revenue,0) Sales_revenue
FROM cte2
LEFT JOIN (
  SELECT 
    DISTINCT coffee_name, 
    FORMAT_DATE('%a', date) Week_day,
    ROUND(SUM(money),2) Sales_revenue
  FROM `Coffee_shop.Sales data`
  GROUP BY coffee_name, FORMAT_DATE('%a', date)
) USING(coffee_name, Week_day)
ORDER BY r;
