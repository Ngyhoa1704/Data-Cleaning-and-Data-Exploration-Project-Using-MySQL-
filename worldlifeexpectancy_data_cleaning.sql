-- PART 1: Data Cleaning

-------------------------------------------------
-- 1. Handling Missing Values

-- 1.1. Identify missing value in the dataset

SELECT * 
FROM worldlifeexpectancy
WHERE Status = '' OR Status IS NULL;

SELECT * 
FROM worldlifeexpectancy
WHERE Lifeexpectancy = '' OR Lifeexpectancy IS NULL;

-- 1.2. Handle missing values: "Status"

/* For the "status" column, use the "status" data from the same country in 
the remaining years to replace the missing value */


UPDATE worldlifeexpectancy
SET Status = 'Developing'
WHERE Country IN ('Afghanistan', 'Albania' ,'Georgia', 'Vanuatu', 'Zambia');

UPDATE worldlifeexpectancy
SET Status = 'Developed' 
WHERE Country = 'United States of America';


/* For the "Lifeexpectancy" column, use the average value of the previous year and the next year 
to replace the missing value */


UPDATE worldlifeexpectancy
SET Lifeexpectancy = '59.1'
WHERE Country = 'Afghanistan' AND Lifeexpectancy = '';

UPDATE worldlifeexpectancy
SET Lifeexpectancy = '76.5'
WHERE Country = 'Albania' AND Lifeexpectancy = '';

-------------------------------------------------
-- 2. Data Consistency

-- 2.1. Check for inconsistencies in categorical columns such as "Country" and "Status"
SELECT DISTINCT Country 
FROM worldlifeexpectancy;

/* Data in the "Country" column has many non-standard values - For example: Iran (Islamic Republic of)
-> Needs to be changed to Islamic Republic of Iran to standardize with other values, similarly with other values */

-- 2.2.: Handle inconsistencies in categorical column such as "Country" and "Status"

UPDATE worldlifeexpectancy
SET Country = 'Plurinational State of Bolivia'
WHERE Country = 'Bolivia (Plurinational State of)';

UPDATE worldlifeexpectancy
SET Country = 'Islamic Republic of Iran'
WHERE Country = 'Iran (Islamic Republic of)';

UPDATE worldlifeexpectancy
SET Country = 'Federated States of Micronesia'
WHERE Country = 'Micronesia (Federated States of)';

UPDATE worldlifeexpectancy
SET Country = 'Bolivarian Republic of Venezuela'
WHERE Country = 'Venezuela (Bolivarian Republic of)';


-------------------------------------------------
-- 3. Removing Duplicates:

-- 3.1. Find duplicates by using the first three columns (Country, Year, Status)
WITH rn_table AS (
SELECT
	Country, 
    Year,
    Status,
    Row_id,
    ROW_NUMBER() OVER(PARTITION BY Country, Year, Status ORDER BY Year) AS rn
FROM worldlifeexpectancy
)
SELECT * FROM rn_table WHERE rn > 1;

-- 3.2. Delete duplicate values from the table
DELETE FROM worldlifeexpectancy
WHERE Row_ID IN (
SELECT
	Row_ID
FROM
(SELECT
    Row_ID,
    ROW_NUMBER() OVER(PARTITION BY Country, Year, Status ORDER BY year) AS rn
FROM worldlifeexpectancy
) AS t
WHERE rn > 1
);

-- 4. Outlier Detection and Treatment:

SELECT * 
FROM worldlifeexpectancy
WHERE Country = 'Afghanistan';

/* Check visually the data for Afghanistan to see if there are outliers and what kind of outliers there are */
/* The column AdultMortality has one value of 3 which is very different from the usual values of this column. If we use only the Z-score method 
and replace it with the mean value, it will not be accurate dut to the influence of outliers. Therefore, use the IQR method to identify the outliers as well */

-- 4.1. Lifeexpectancy 

-- 4.1.1. Find Outlier

-- Create a temporary table to store the number of rows in each group 
DROP TEMPORARY TABLE IF EXISTS country_stats;
CREATE TEMPORARY TABLE country_stats AS 
SELECT country, COUNT(*) AS total_rows
FROM worldlifeexpectancy
GROUP BY country;

SELECT * FROM worldlifeexpectancy;
-- Use the ROW_NUMBER() window functions to assign a sequential number to each value within each group
WITH rn AS (
SELECT
	Country,
    Year,
    Lifeexpectancy,
    ROW_NUMBER() OVER(PARTITION BY Country ORDER BY Lifeexpectancy) AS row_num
FROM
	worldlifeexpectancy
),
-- SELECT * FROM rn;
-- Calcualte Q1 and Q3 for each country group 
quartiles AS (
SELECT
	rn.Country,
    CASE
		WHEN total_rows < 4 THEN MIN(lifeexpectancy) 
        ELSE MAX(CASE WHEN row_num <= 0.25 * total_rows THEN lifeexpectancy END)
	END AS Q1,
    CASE
		WHEN total_rows < 4 THEN MAX(lifeexpectancy)
        ELSE MAX(CASE WHEN row_num <= 0.75 * total_rows THEN lifeexpectancy END)
	END AS Q3
FROM
	rn
    JOIN
    country_stats cs ON rn.Country = cs.Country
GROUP BY rn.Country, total_rows
),
iqr AS (
SELECT
	Country,
    Q1,
    Q3,
    Q3 - Q1 AS IQR,
    Q1 - 1.5 * (Q3 - Q1) AS lower_bound,
    Q3 + 1.5 * (Q3 - Q1) AS upper_bound
FROM 
	quartiles
),
outlier_iqr AS (
SELECT
	w.Country,
    w.Year,
    w.Lifeexpectancy,
    CASE 
		WHEN lifeexpectancy < lower_bound THEN 'Below Lower Boynd'
        WHEN lifeexpectancy > upper_bound THEN 'Above Upper Bound'
		ELSE 'Within range'
	END AS outlier_status_iqr
FROM
	worldlifeexpectancy w
    JOIN
    iqr ON w.Country = iqr.Country 
),
-- SELECT * FROM outlier_iqr
-- Calcualte mean and z-score
stats AS (
SELECT
	Country,
    AVG(lifeexpectancy) AS mean,
    STDDEV(lifeexpectancy) AS std_dev
FROM
	worldlifeexpectancy
GROUP BY Country
),
zscore AS (
SELECT
	w.Country,
    w.Year,
    w.Lifeexpectancy,
    (w.Lifeexpectancy - s.mean) / s.std_dev AS z_score
FROM 
	worldlifeexpectancy w
    JOIN 
    stats s ON s.Country = w.Country 
),
zscore_outlier_status AS (
SELECT
	Country,
    Year,
    Lifeexpectancy,
    CASE
		WHEN ABS(z_score) > 3 THEN 'Outlier'
        ELSE 'Normal'
	END AS status_zscore
FROM
	zscore
)
-- SELECT * FROM zscore_outlier_status WHERE status_zscore = 'Outlier'
-- Combine two methods
SELECT
	iqr.Country,
    iqr.Year,
    iqr.Lifeexpectancy,
    iqr.outlier_status_iqr,
    zscore.status_zscore
FROM
	zscore_outlier_status zscore
    JOIN
    outlier_iqr iqr ON iqr.Country = zscore.Country AND iqr.Year = zscore.Year
WHERE outlier_status_iqr <> 'Within range' AND status_zscore = 'Outlier';


-- 4.1.2. Handle Outlier

-- Check if the outliers are reasonable.

SELECT *
FROM worldlifeexpectancy
WHERE country IN ('Cabo Verde', 'Eritrea', 'Haiti', 'Libya', 'Paraguay');


/* 5 outliers:
- Cabo Verde (2009): 77 -> Not unusually high compared to other years, sot it can be ignored
- Eritrea (2007): 45.3 -> The first year, so it might be low, life expectancy increases in subsequent years, so it can be ignored
- Haiti (2017): 36.3 -> Unusually low, and the mortality rate in 2017 is also high -> Needs further investment to identify any issues.
- Libya (2007): 78 -> Not unusually high compared to other years, so it can be ignored
- Paraguay (2007): 79 -> Not unusually high compared to other years, so it can be ignored. */

/* According to the actual data, there was nothing unusual in Haity in 2017, so the sudden drop in lifeexpectancy is not reasonable.
--> Replace the outlier with the average value. */

UPDATE worldlifeexpectancy w
JOIN (
SELECT
	Country,
	ROUND(AVG(lifeexpectancy),1) AS avg
FROM
	worldlifeexpectancy
WHERE Country = 'Haiti'
GROUP BY Country
) avg_t ON w.Country = avg_t.Country
SET w.Lifeexpectancy = avg_t.avg
WHERE w.Country = 'Haiti' AND YEAR = 2017;




-- 4.2. AdultMortality

-- 4.2.1 Find Outlier:
CREATE TEMPORARY TABLE temp_outliers AS
WITH rn AS (
SELECT
	Country,
    Year,
    AdultMortality,
    ROW_NUMBER() OVER(PARTITION BY Country ORDER BY AdultMortality) AS row_num
FROM 
	worldlifeexpectancy
),
-- SELECT * FROM rn
quartiles AS (
SELECT
	rn.Country,
    CASE 
		WHEN total_rows < 4 THEN MIN(AdultMortality)
        ELSE MAX(CASE WHEN row_num <= 0.25 * total_rows THEN AdultMortality END)
	END AS Q1,
    CASE
		WHEN total_rows < 4 THEN MAX(AdultMortality)
        ELSE MAX(CASE WHEN row_num <= 0.75 * total_rows THEN AdultMortality END)
	END AS Q3
FROM
	rn
    JOIN
    country_stats cs ON rn.Country = cs.Country 
GROUP BY rn.Country, cs.total_rows
),
-- SELECT * FROM quartiles;
iqr AS (
SELECT
	Country,
	Q1,
    Q3,
    Q3 - Q1 AS IQR,
    Q1 - 1.5 * (Q3 - Q1) AS lower_bound,
    Q3 + 1.5 * (Q3 - Q1) AS upper_bound
FROM
	quartiles 
),
-- SELECT * FROM iqr;
iqr_outliers AS (
SELECT
	w.Country,
    w.Year,
    w.AdultMortality,
    CASE
		WHEN w.AdultMortality < lower_bound THEN 'Below Lower Bound'
        WHEN w.AdultMortality > upper_bound THEN 'Above Upper Bound'
        ELSE 'Within Range'
	END AS iqr_status
FROM
	worldlifeexpectancy w
    JOIN
    iqr ON w.Country = iqr.Country 
),
-- SELECT * FROM iqr_outliers
stats AS (
SELECT
	Country,
    AVG(AdultMortality) AS mean,
    STDDEV(AdultMortality) AS std_dev
FROM
	worldlifeexpectancy
GROUP BY Country
),
-- SELECT * FROM stats;
zscore AS (
SELECT
	w.Country,
    w.Year,
    w.AdultMortality,
    CASE 
		WHEN std_dev = 0 THEN 0
		ELSE (w.AdultMortality - s.mean) / s.std_dev 
	END AS z_score
FROM
	stats s
    JOIN
    worldlifeexpectancy w ON s.Country = w.Country 
),
-- SELECT * FROM zscore;
zscore_status AS (
SELECT
	Country,
    Year,
    AdultMortality,
    CASE
		WHEN ABS(z_score) > 3 THEN 'Outliers'
        ELSE 'Normal'
	END AS z_score_status
FROM 
	zscore
)
-- SELECT * FROM zscore_status;
SELECT
	z.Country,
    z.Year,
    z.AdultMortality,
    z_score_status,
    iqr_status
FROM
	zscore_status z
    JOIN iqr_outliers iqr ON z.Country = iqr.Country AND z.Year = iqr.Year
WHERE z_score_status = 'Outliers' AND iqr_status <> 'Within Range';


-- SELECT * FROM temp_outliers;

-- 4.2.2. Handle Outlier:

UPDATE worldlifeexpectancy
SET AdultMortality = 300
WHERE Country = 'Afghanistan' AND YEAR = 2009;

UPDATE worldlifeexpectancy
SET AdultMortality = 60
WHERE Country = 'Australia' AND YEAR = 2021;

UPDATE worldlifeexpectancy
SET AdultMortality = 140
WHERE Country = 'Bangladesh' AND YEAR = 2018;

-- After updateing some outliers, I realized that the outliers appear due to missing zeros --> Add zeros to the AdultMortality values of the outliers rows
UPDATE worldlifeexpectancy w
JOIN temp_outliers t ON w.Country = t.Country AND w.Year = t.Year
SET w.AdultMortality = CONCAT(w.AdultMortality, '0') ;


SELECT * FROM worldlifeexpectancy 
WHERE (Country, Year) IN (
SELECT
	Country,
    Year
FROM
	temp_outliers
);


-- 4.3. GDP

-- 4.3.1. Find Outlier
WITH rn AS (
SELECT
	Country,
    Year,
    GDP,
    ROW_NUMBER() OVER(PARTITION BY Country ORDER BY GDP) AS row_num
FROM
	worldlifeexpectancy
),
-- SELECT * FROM rn;
quartiles AS (
SELECT
	rn.Country,
    CASE
		WHEN total_rows < 4 THEN MIN(GDP)
        ELSE MAX(CASE WHEN row_num <= 0.25 * total_rows THEN GDP END)
	END AS Q1,
    CASE
		WHEN total_rows < 4 THEN MAX(GDP)
        ELSE MAX(CASE WHEN row_num <= 0.75 * total_rows THEN GDP END)
	END AS Q3
FROM
	rn
    JOIN
    country_stats cs ON rn.Country = cs.Country
GROUP BY rn.Country, cs.total_rows
),
-- SELECT * FROM quartiles;
iqr AS (
SELECT
	Country,
    Q1,
    Q3,
    Q3 - Q1 AS IQR,
    Q1 - 1.5 * (Q3 - Q1) AS lower_bound,
    Q3 + 1.5 * (Q3 - Q1) AS upper_bound
FROM 
	quartiles
),
-- SELECT * FROM iqr;
iqr_outliers AS (
SELECT
	w.Country,
    w.Year,
    w.GDP,
    iqr.lower_bound,
    iqr.upper_bound,
    CASE 
		WHEN GDP < lower_bound THEN 'Below Lower Bound'
        WHEN GDP > upper_bound THEN 'Above Upper Bound'
        ELSE 'Within Range'
	END AS iqr_status
FROM
	worldlifeexpectancy w
    JOIN
    iqr ON w.Country = iqr.Country
),
-- SELECT * FROM iqr_outliers;
stats AS (
SELECT
	Country,
    AVG(GDP) AS mean,
    STDDEV(GDP) AS std_dev
FROM
	worldlifeexpectancy
GROUP BY Country
),
-- SELECT * FROM stats;
zscore AS (
SELECT
	w.Country,
    w.Year,
    w.GDP,
	(w.GDP - s.mean) / s.std_dev AS z_score
FROM
	stats s
    JOIN
    worldlifeexpectancy w ON s.Country = w.Country
),
-- SELECT * FROM zscore
zscore_outliers AS (
SELECT
	Country,
    Year,
    GDP,
    CASE
		WHEN ABS(z_score) > 3 THEN 'Outliers'
        ELSE 'Normal'
	END AS z_score_status
FROM 
	zscore
)
-- SELECT * FROM zscore_outliers;
SELECT
	z.Country,
    z.Year,
    z.GDP,
    z_score_status,
    iqr_status
FROM
	zscore_outliers z
    JOIN
    iqr_outliers iqr ON z.Country = iqr.Country
WHERE z_score_status = 'Outliers' AND iqr_status <> 'Within Range';

-- 4.3.2 Handle Outliers by using Average

SELECT *
FROM worldlifeexpectancy
WHERE Country = 'Belize';

/* 1 outlier Belize (2015): 447
the issue might be due to the missing "0".
--> Add extra zeros to the end of the value. */

UPDATE worldlifeexpectancy
SET GDP = 4470
WHERE Country = 'Belize' AND YEAR = 2015;

-- 4.4. Checking and Deleting incomplete data
CREATE TEMPORARY TABLE t1 AS 
WITH row_totals AS (
SELECT
	Country,
    COUNT(*) AS total_rows
FROM
	worldlifeexpectancy
GROUP BY Country
)
SELECT * FROM row_totals WHERE total_rows = 1;

/* 10 countries with incomplete data in comparison with other countries when checking the data for Life Expectancy, Adult Mortality, and Infant Deaths shows all values as 0,
which are unfeasable 
--> Remove these rows to prevent them from affecting the overall results */
DELETE FROM worldlifeexpectancy 
WHERE Country IN (
SELECT
	Country
FROM t1
);

-- Double check whether these countries have been deleted or not
SELECT * FROM worldlifeexpectancy
WHERE Country IN (
SELECT
	Country
FROM t1
);







