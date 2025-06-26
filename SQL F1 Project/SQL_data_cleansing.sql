/* 
All data cleansing process was done on Google Big Query 
All visulizationn was done on Power BI
Definition:
    Podium driver: Driver that has get at least 1 podium in his/her career
    DNF: DNF stand for "Did not finish"  --> Cause by various reason like collision, technical issues, driver feeling sick, etc.

All data are extracted from Kaggle (https://www.kaggle.com/datasets/rohanrao/formula-1-world-championship-1950-2020)
Races: 1950 ROUND 1 British Grand Prix TO 2024 ROUND 24 Abu Dhabi
Results: 1950 ROUND 1 British Grand Prix TO 2024 ROUND 13 Hungarian Grand Prix

*/

/* To extract the DNF rate and DNF number per year and group by nationality --> Result in file "DNF rate per year" */
SELECT 
  DISTINCT drivers.nationality,
  races.year,
  COUNT(results.position = '\\N') Number_of_accident,
FROM `F1.results` results
JOIN `F1.drivers` drivers USING(driverId)
JOIN `F1.races` races USING(raceId)
GROUP BY nationality, year
ORDER BY nationality, year;


/* To count the number of driver by nationality and year --> Result in file "Nationality count by year" */
/* Step 1: Create a temporary table to join all year and nationality */
WITH cte AS(SELECT 
  DISTINCT nationality,
  year,
FROM `F1.races` 
CROSS JOIN `F1.drivers` drivers 
GROUP BY nationality, year
ORDER BY nationality, year DESC)
/* Step 2: Base on the tempory table, select all appropriate columns */
SELECT 
  drivers.nationality, 
  year, 
  count(DISTINCT driverId) Count
from F1.results 
JOIN F1.races USING(raceId)
JOIN F1.drivers drivers USING(driverId)
GROUP BY nationality, year
ORDER BY nationality, year DESC;


/* To summarize all accidents and abnormal events and group it by nationality --> Result in file "Race status" */
SELECT 
  DISTINCT nationality, 
  status.statusId, 
  status.status, 
  COUNT(driverId)
FROM `f1data-463811.F1.results` results 
JOIN `f1data-463811.F1.status` status USING(statusId)
JOIN `f1data-463811.F1.drivers` drivers USING(driverId)
GROUP BY nationality, statusId, status;


/* To summarize all drivers performance by number of DNF, number of race joined, DNF rate and the average finish position, group by nationality --> Result in file "Overall Performances */
/* Step 1: Create a temporary table to concatenate the forname and surname of drivers */
WITH 
cte AS(SELECT *, CONCAT(forename, surname) name
  FROM`f1data-463811.F1.drivers`),
filtered_results AS     /* Step 2: Create another temporary table to join the cte table with all other related tables and change the position column from str to int whhile replacing any unfinshed (DNF) status to NULL value for calculation*/
(SELECT 
  results.resultId,
  results.raceId,
  results.driverId,
  cte.name,
  cte.nationality,
  results.position,
  CASE
    WHEN position = '\\N' THEN NULL
    ELSE PARSE_NUMERIC(position)
  END AS ending_position
FROM `f1data-463811.F1.results` results
JOIN cte USING(driverId)
ORDER BY raceId, resultId)
/* Step 3: Select all related columns while using [position = '\\N'] to count for DNF and round all result to 2 decimal place */
SELECT 
  DISTINCT nationality, 
  COUNTIF(filtered_results.position = '\\N') Number_of_DNF,
  COUNT(filtered_results.position) Number_of_race,
  ROUND(COUNTIF(filtered_results.position = '\\N') / COUNT(filtered_results.position),2) DNF_percentage,
  ROUND(AVG(ending_position),2) AVG_finish_position
FROM filtered_results
GROUP BY nationality;


/* To count the number of podium driver and number of podium they have got. Group the result in nationality --> Results in file "Podium driver per country" */
/* Create a temporary table to find total number of driver in each nationality */
With filter AS(SELECT 
  results.resultId, 
  results.raceId, 
  results.driverId, 
  drivers.nationality, 
  position
FROM `f1data-463811.F1.results` AS results
JOIN `f1data-463811.F1.drivers` AS drivers USING(driverId)
JOIN `f1data-463811.F1.races` AS races USING(raceId)
ORDER BY results.resultId)
/* Select all related data */
SELECT
  DISTINCT filter.nationality, 
  COUNT(DISTINCT driverId) Number_of_podium_driver,
  COUNT(driverId) Number_of_podium,
  ROUND(COUNT(driverId)/ COUNT(DISTINCT driverId), 2) podium_per_person,
FROM filter
WHERE position IN ('1','2','3')
GROUP BY nationality;


/* To calculate the percentage of driver that is a podium driver (A driver that have get at least 1 podium position) --> Results in file "Podium driver percentage" */
WITH cte AS (SELECT 
  DISTINCT nationality, 
  COUNT(driverId) number_of_driver
FROM `f1data-463811.F1.drivers` drivers
GROUP by nationality)

SELECT 
  nationality, 
  number_of_driver, 
  number_of_podium_driver, 
  ROUND(IFNULL(number_of_podium_driver/number_of_driver , 0),2)  podium_driver_percentage, 
  IFNULL(ROUND(number_of_podium / number_of_driver,2),0) podium_per_driver
FROM cte
LEFT JOIN `f1data-463811.F1.Podium_driver_per_country` USING(nationality)
ORDER BY Number_of_podium DESC;


/* To filter only the top 3 driver in every nationality base on percentage they got podium, top 3 driver should have the highest podium percentage, if it is the same, then he/she should have the highest average finish position, if it is also the same, then we will consider the one participated in fewer race is better  --> Results in file "Driver rank by podium percentage" */
/* Step 1: Create a temporary table to concatenate all driver's name, replace DNF driver position to 0 (For counting purpose) and  NULL (For taking the average position) */
WITH cte1 AS (SELECT 
  driverId,
  nationality,
  CONCAT(forename," ", surname) Full_name,
  CASE
    WHEN position = '\\N' THEN 0
    ELSE PARSE_NUMERIC(position)
  END AS ending_position_for_count,
  CASE
    WHEN position = '\\N' THEN NULL
    ELSE PARSE_NUMERIC(position)
  END AS ending_position_for_rank
FROM `f1data-463811.F1.drivers` drivers
JOIN `f1data-463811.F1.results` results USING(driverId)
),
/* Step 2: Base on the previous table, summarize the podium percenatge and the average finish position as benchmark to evaluate driver's performance. */
cte2 AS (SELECT
  DISTINCT Full_name,
  driverId,
  nationality,
  COUNT(ending_position_for_count) Race_count,
  ROUND(COUNTIF(ending_position_for_count IN (1,2,3)) / COUNT(ending_position_for_count),2) Podium_percentage,
  ROUND(AVG(ending_position_for_rank),2) AVG_finish_position
FROM cte1
GROUP BY Full_name, driverId, nationality
),
/* Step 3: Base on cte2, rank drivers by benchmark */
cte3 AS(
  SELECT 
    *,
    ROW_NUMBER() OVER(PARTITION BY nationality ORDER BY Podium_percentage DESC, AVG_finish_position, Race_count) rank_by_podium_percentage
  FROM cte2
  ORDER BY nationality, rank_by_podium_percentage
)
/* Step 4: Only select top 3 drivers from each nationality */
SELECT 
  * 
FROM cte3 
WHERE rank_by_podium_percentage IN (1,2,3) 
ORDER BY nationality, rank_by_podium_percentage;


/* To filter only the top 3 driver in every nationality base on number of podium they got, top 3 driver should have the highest number of podium, if it is the same, then he/she should have the highest average finish position, if it is also the same, then we will consider the one participated in fewer race is better  --> Results in file "Driver rank by podium" */
/* Step 1: Create a temporary table to concatenate all driver's name, replace DNF driver position to 0 (For counting purpose) and  NULL (For taking the average position) */
with cte1 AS (SELECT 
  driverId,
  nationality,
  CONCAT(forename," ", surname) Full_name,
  CASE
    WHEN position = '\\N' THEN 0
    ELSE PARSE_NUMERIC(position)
  END AS ending_position_for_count,
  CASE
    WHEN position = '\\N' THEN NULL
    ELSE PARSE_NUMERIC(position)
  END AS ending_position_for_rank
FROM `f1data-463811.F1.drivers` drivers
JOIN `f1data-463811.F1.results` results USING(driverId)
),
/* Step 2: Base on the previous table, summarize the podium count, race count and the average finish position as benchmark to evaluate driver's performance. */
cte2 AS (SELECT
  DISTINCT Full_name,
  driverId,
  nationality,
  COUNTIF(ending_position_for_count IN (1,2,3)) Podium_count,
  COUNT(ending_position_for_count) Race_count,
  ROUND(AVG(ending_position_for_rank),2) AVG_finish_position
FROM cte1
GROUP BY Full_name, driverId, nationality
)
/* Step 3: Base on cte2, rank drivers by benchmark */
cte3 AS(
  SELECT 
    *,
    ROW_NUMBER() OVER(PARTITION BY nationality ORDER BY Podium_count DESC, AVG_finish_position, Race_count) rank_by_podium
  FROM cte2
  ORDER BY nationality, rank_by_podium
)
/* Step 4: Only select top 3 drivers from each nationality */
SELECT 
  * 
FROM cte3 
WHERE rank_by_podium IN(1,2,3) 
ORDER BY nationality, rank_by_podium;
