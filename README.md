# World Life Expectancy SQL Project

This project focuses on cleaning and preparing a real-world dataset named `worldlifeexpectancy` for further analysis. The dataset contains annual records of health and socioeconomic indicators for various countries.

## Dataset Overview

The `worldlifeexpectancy` table includes:

| Column Name              | Description                                                                 |
|--------------------------|-----------------------------------------------------------------------------|
| `Country`                | Country name                                                               |
| `Year`                   | Year of the record                                                         |
| `Status`                 | Development status of the country (`Developed` or `Developing`)            |
| `Lifeexpectancy`         | Average life expectancy (years)                                            |
| `AdultMortality`         | Adult mortality rate per 1,000 people                                      |
| `infantdeaths`           | Infant mortality rate per 1,000 live births                                |
| `percentageexpenditure`  | % of GDP spent on healthcare                                               |
| `Measles`                | Number of reported measles cases                                           |
| `BMI`                    | Average Body Mass Index                                                    |
| `under_fivedeaths`       | Deaths of children under 5 per 1,000 live births                           |
| `Polio`                  | Number of reported polio cases                                             |
| `Diphtheria`             | Number of reported diphtheria cases                                        |
| `HIVAIDS`                | HIV/AIDS prevalence rate                                                   |
| `GDP`                    | Gross Domestic Product                                                     |
| `thinness_1_19_years`    | Prevalence of thinness (age 1–19)                                          |
| `thinness_5_9_years`     | Prevalence of thinness (age 5–9)                                           |
| `Schooling`              | Average years of schooling (age 25+)                                       |
| `Row_ID`                 | Unique row identifier                                                      |

---

## Part 1: Data Cleaning Process

### 1. Handling Missing Values
- **Status**: Filled missing values based on country context.
- **Lifeexpectancy**: Replaced missing entries using average of adjacent years.

### 2. Ensuring Data Consistency
- Standardized country names (e.g., changed `Iran (Islamic Republic of)` → `Islamic Republic of Iran`)
- Verified unique values in categorical fields.

### 3. Removing Duplicates
- Identified and deleted exact row duplicates using `ROW_NUMBER()`.

### 4. Outlier Detection and Treatment

#### Lifeexpectancy, AdultMortality, and GDP:
- Outliers detected using both **Z-Score** and **IQR** methods.
- Some outliers fixed by:
  - Averaging adjacent years
  - Adding missing trailing zeroes
  - Replacing clearly invalid entries

#### Example Fix:
- `Haiti (2017)` had an unreasonable drop in Life Expectancy → Replaced with mean of other years.
- GDP for `Belize (2015)` changed from `447` → `4470` due to formatting error.

### 5. Deleting Incomplete Records
- Countries with only one data entry and all null/zero values were removed to avoid skewing results.



# World Life Expectancy SQL Project - Part 2: Exploratory Data Analysis (EDA)

This project is a continuation of the Data Cleaning phase, applying SQL-based Exploratory Data Analysis (EDA) on the cleaned worldlifeexpectancy dataset. The dataset includes socioeconomic and health indicators across countries and years.

## Key Questions Explored

### 1. Descriptive Statistics
Calculated mean, median, min, and max Life Expectancy for each country.
Assessed mode but found no dominant repeating values due to wide distribution.

### 2. Life Expectancy Trend Analysis
Analyzed Life Expectancy over time (e.g., Afghanistan) to detect positive growth trends.

### 3. Developed vs. Developing Countries
Compared average Life Expectancy in 2022:
Developed: 80.7 years
Developing: 69.7 years

### 4. Mortality Correlation
AdultMortality and Lifeexpectancy correlation: -0.67
Strong negative correlation

### 5. GDP Influence
Countries grouped by Low, Medium, and High GDP:
Life expectancy increases with GDP level
High GDP: 77.84 years, Low GDP: 62.92 years

### 6. Disease Impact
Measles: Higher cases linked with lower life expectancy
High: 62.8, Low: 71.4
Polio: Unexpected trend (possibly due to reporting bias or data quality)

### 7. Schooling Impact
Countries with highest schooling (e.g., Japan) had higher life expectancy
Data inconsistency noted for countries like USA, UK, Korea with 0 years schooling

### 8. BMI Trends
Tracked BMI change over time (e.g., Albania)
Found BMI increase trend, with some outliers

### 9. Infant Mortality
Compared countries with highest vs. lowest life expectancy:
Japan: Infant deaths = 2.8
Sierra Leone: Infant deaths = 27.5

### 10. Rolling Average Analysis
Applied 5-year rolling average to AdultMortality for smoother trend analysis

### 11. Healthcare Spending
Correlation between percentageexpenditure and Life Expectancy: 0.38
Moderate positive correlation

### 12. BMI & Health Indicators
BMI vs. Lifeexpectancy: Correlation = 0.57
BMI vs. AdultMortality: Correlation = -0.38

### 13. GDP vs Health Outcomes
High GDP countries have:
Higher Life Expectancy
Lower AdultMortality & InfantDeaths

### 14. Regional Comparison
Grouped countries by continent
Found regional disparities in Life Expectancy:
Europe: Highest (~77.4 years)
Africa: Lowest (~58.6 years)

## Tools Used
SQL (MySQL) for analysis
Window Functions: ROW_NUMBER(), AVG() OVER for trend & percentile insights
CTEs for logical separation and reuse of query logic

## Author
Credit to: Ms tuhoang3112 (Zoe) for guiding this project and Self-study Data Discord Group for Dataset provider



