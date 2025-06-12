-- PART 2: EDA

-- 1. Basic Descriptive Statistics: Query to get the mean, median, minimum, and maximum of the Lifeexpectancy for each country 
USE datacleaningproject;
-- Calculating the Mode of Life Expectancy
SELECT * FROM worldlifeexpectancy;
WITH frequency_table AS (
SELECT
	Country,
    Lifeexpectancy,
    COUNT(*) AS frequency
FROM
	worldlifeexpectancy
GROUP BY Country, Lifeexpectancy
),
max_frequency_table AS (
SELECT
	Country,
    MAX(frequency) AS max_frequency
FROM
	frequency_table
GROUP BY Country
)
SELECT
	ft.Country,
    ft.Lifeexpectancy,
    ft.frequency
FROM
	max_frequency_table mft
    JOIN 
    frequency_table ft ON ft.Country = mft.Country AND mft.max_frequency = ft.frequency;
/* Quan sát ta thấy các giá trị trong Lifeexpectancy phân bổ rải rác liên tục, không có giá trị nào lặp lại quá nhiều lần
(hầu hết là 1, 2 lần) không có quá nhiều insight nên tập trung và các giá trị thống kê khác */

-- Calculating the Median, Mean, Maximum, and Minimum of Life Expectancy
SELECT
	Country,
    COUNT(*) AS count_rows
FROM
	worldlifeexpectancy
GROUP BY Country;

-- Vì với mỗi "Country" có tổng cộng 16 dòng (là số chẵn) ==> median bằng (n + 1) / 2:  trung bình cộng của 2 số chính giữa (8,9)
WITH rn AS (
SELECT
	Country,
    Year,
    Lifeexpectancy,
    ROW_NUMBER() OVER(PARTITION BY Country ORDER BY Lifeexpectancy) AS row_num
FROM
	worldlifeexpectancy
),
median_table AS (
SELECT
	Country,
    ROUND(AVG(Lifeexpectancy),1) AS median_lifeexpectancy
FROM
	rn
WHERE row_num IN (8,9)
GROUP BY Country
),
statistics_table AS (
SELECT
	Country,
    ROUND(AVG(lifeexpectancy),1) AS mean_lifeexpectancy,
    MAX(lifeexpectancy) AS max_lifeexpectancy,
    MIN(lifeexpectancy) AS min_lifeexpectancy
FROM
	worldlifeexpectancy 
GROUP BY Country
)
SELECT
	mt.Country,
    st.mean_lifeexpectancy,
    mt.median_lifeexpectancy,
    st.max_lifeexpectancy,
    st.min_lifeexpectancy
FROM
	median_table mt
    LEFT JOIN
    statistics_table st ON mt.Country = st.Country;
    
-- 2. Trend Analysis: Query to find the trend of Lifeexpectancy over the years for a specific country (e.g., Afghanistan)

SELECT 
	Country,
    Year,
    Lifeexpectancy
FROM
	worldlifeexpectancy
WHERE Country = 'Afghanistan'
ORDER BY  Year;
-- Nhìn chung Life Expectency có xu hướng tăng ở Afghanistan 


-- 3. Comparitive Analysis: Query to compare the average Life Expectancy between Developed and Developing countries for the latest available year.
SELECT
	year,
    status,
    ROUND(AVG(Lifeexpectancy),1) 
FROM
	worldlifeexpectancy
WHERE year = 2022
GROUP BY year, status;
-- Tuổi thọ trung bình của nước phát triển cao hơn nước đang phát triển (80.7 > 69.7)

-- 4. Mortality Analysis: Query to calculate the correlation between AdultMortality and Lifeexpectancy for all countries.

SELECT
	(COUNT(*) * SUM(xy) - SUM(x) * SUM(y)) / 
    SQRT((COUNT(*) * SUM(xx) - SUM(x) * SUM(x)) * (COUNT(*) * SUM(yy) - SUM(y) * SUM(y))) AS correlation
FROM (
SELECT 
	AdultMortality AS x,
    Lifeexpectancy AS y,
    AdultMortality * Lifeexpectancy AS xy,
    AdultMortality * AdultMortality AS xx,
    Lifeexpectancy * Lifeexpectancy AS yy
FROM
	worldlifeexpectancy
WHERE AdultMortality IS NOT NULL AND Lifeexpectancy IS NOT NULL
) AS t;

/* Hệ số tương quan là -0.67, mối tương quan giữa AdultMortality và Lifeexpectancy là âm và có cường độ tương đối mạnh (moderate correlation)
đồng nghĩa với việc khi AdultMortality tăng thì LifeExpectancy sẽ giảm. This is correlation, not causation */

-- 5. Impact of GDP: Query to find the average Lifeexpectancy of countries group by their GDP ranges (e.g., low, medium, high)
WITH avg_stats AS (
SELECT
	Country,
    AVG(Lifeexpectancy) AS avg_lifeexpectancy,
    AVG(GDP) AS avg_gdp
FROM
	worldlifeexpectancy
GROUP BY Country
),
gdp_group AS (
SELECT
	Country,
    avg_lifeexpectancy,
    avg_gdp,
    CASE
		WHEN avg_gdp < 1360 THEN 'Low'
        WHEN avg_gdp >= 1360 AND avg_gdp < 6500 THEN 'Medium'
        ELSE 'High'
	END AS gdp_bucket
FROM
	avg_stats
)
SELECT
	gdp_bucket,
    AVG(avg_lifeexpectancy)
FROM
	gdp_group
GROUP BY gdp_bucket;
-- Các nước nằm trong nhóm GDP cao thường có tuổi thọ lớn hơn so với các nước có GDP thấp hơn (77.84 > 70.6 > 62.92)


-- 6. Disease Impact: Query to analyze the impact of Measles and Polio on Lifeexpectancy. Calculate average life expectancy for countries with high and low incidence rate of these diseases.

WITH avg_stats AS (
SELECT
	Country,
    AVG(Measles) AS avg_measles,
    AVG(Lifeexpectancy) AS avg_lifeexpectancy
FROM
	worldlifeexpectancy
GROUP BY Country
),
measles_group AS (
SELECT
	Country,
    avg_lifeexpectancy,
    CASE
		WHEN avg_measles > 50000 THEN 'High'
        WHEN avg_measles < 1000 THEN 'Low'
        ELSE 'Medium'
	END AS measles_bucket
FROM
	avg_stats 
)
SELECT
	measles_bucket,
    AVG(avg_lifeexpectancy)
FROM
	measles_group
GROUP BY measles_bucket
ORDER BY AVG(avg_lifeexpectancy);

-- Những nước có ca nhiễm bệnh Meales cao thì trung bình Life Expectancy là 62.8
-- Những nước có ca nhiễm bệnh Meales thấp thì trung bình Life Expectancy là 71.4
-- --> Kết quả hợp lí vì tỉ lệ nhiễm bệnh cao thì thường dẫn đến tỉ lệ tử vong cao, làm cho tuổi thọ giảm

SELECT * FROM worldlifeexpectancy;
-- Average Life Expectancy with Polio disease rate

WITH avg_stats AS (
SELECT
	Country,
    AVG(Lifeexpectancy) AS avg_lifeexpectancy,
    AVG(Polio) AS avg_polio
FROM 
	worldlifeexpectancy
GROUP BY Country
),
polio_group AS (
SELECT
	Country,
    avg_lifeexpectancy,
    avg_polio,
    CASE 
		WHEN avg_polio >= 90 THEN 'High'
        WHEN avg_polio < 50 THEN 'Low'
        ELSE 'Medium'
        END AS polio_bucket
FROM
	avg_stats
)
SELECT
	polio_bucket,
    AVG(avg_lifeexpectancy)
FROM
	polio_group
GROUP BY polio_bucket;

-- Những nước mắc bệnh Polio mức cao thì tuổi thọ trung bình là 74.75
-- Với nước mắc bệnh Polio mức thấp thì tuổi thọ trung bình là 52.49
-- Kết quả không giống như dự đoán vì các nước có tỉ lệ nhiễm bệnh cao thì lại có tuổi thọ cao hơn các nước có tỉ lệ mắc bệnh thấp

/* Nguyên nhân:
- Measles (bệnh sởi) là bệnh có nguy cơ gây tử vong cao và tốc đô lây lan nhanh chóng, đặc biệt ở những nước có tỉ lệ tiêm chủng thấp
- Polio (Bại liệt) nghiêm trọng hơn về mặt biến chứng lâu dài như liệt cơ và hậu quả lâu dài đối với sức khỏe.
--> Nguyên nhân co thể do phần lớn các trường hợp nhiễm Polio không dẫn đến tử vong có thể khiến tuổi thọ không bị ảnh hưởng */

-- 7.Schooling and Health: Query to determine the relationship between Schooling and Lifeexpectancy. Find countries with the highest and lowest schooling and their repsective life expectancies
SELECT * FROM worldlifeexpectancy;

WITH avg_stats AS (
SELECT
	Country,
    AVG(lifeexpectancy) AS avg_lifeexpectancy,
    AVG(schooling) AS avg_schooling
FROM
	worldlifeexpectancy
GROUP BY Country
)
SELECT 
	*
FROM avg_stats
WHERE avg_schooling = (SELECT MAX(avg_schooling) FROM avg_stats) 
OR avg_schooling = (SELECT MIN(avg_schooling) FROM avg_stats);

-- Schooling có ảnh hưởng tích cực đến lifeexpectancy, nghĩa là các nước có trình độ học vấn càng cao thì tuổi thọ họ có xu hướng cao
-- Có một số đất nước có sai lệch về data schooling: Korea, UK, US, tuổi thọ cao từ 78 - 80 nhưng schooling được ghi nhận là 0

-- 8. BMI Trends: Query to find the BMI trend over the years for a particular country.
SELECT
	Country,
    Year, 
    BMI
FROM worldlifeexpectancy
WHERE Country = 'Albania'
ORDER BY Year;

-- BMI có xu hướng tăng ở Albania, năm 2013 có 1 outlier 5.8 có thể là do nhập thiếu số 0.

USE datacleaningproject;
-- 9. Infant Mortality: Query to find the average number of infantdeaths and under-fivedeaths for countries with the highest and lowest life expectancies
SELECT * FROM worldlifeexpectancy;
WITH avg_table AS (
SELECT
	Country,
    AVG(lifeexpectancy) AS avg_lifeexpectancy,
    AVG(infantdeaths) AS avg_infantdeaths,
    AVG(under_fivedeaths) AS avg_underfivedeaths
FROM
	worldlifeexpectancy
GROUP BY  Country
)
SELECT * FROM avg_table
WHERE avg_lifeexpectancy = (SELECT MAX(avg_lifeexpectancy) FROM avg_table)
OR avg_lifeexpectancy = (SELECT MIN(avg_lifeexpectancy) FROM avg_table)
;
-- Đất nước có tuổi thọ trung bình cao nhất là Japan, avg infant deaths là 2.8 và  avg under five deaths là 4
-- Đất nước có tuổi thọ trung bính thấp nhất là Sierra Leone - 46.1, avg infant deaths là 27.5 và avg under five deaths là 41.8

-- 10. Rolling Average of Adult Mortality: Query to calculate the rolling average of Adult Mortality over a 5-year window for each country. This will help in understanding the trend and smoothing out short-term fluctuations.
SELECT
	Country,
    Year,
    AdultMortality,
    AVG(AdultMortality) OVER(PARTITION BY Country ORDER BY year ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING) AS rolling_avg_5yr
FROM
	worldlifeexpectancy
WHERE Country = 'Viet Nam';
-- Lấy Việt Nam làm ví dụ, có thể nhận thấy AdultMortality rolling_avg_5yr ở Việt Nam giảm dần qua các năm 

-- 11. Impact of Healthcare Expenditure: Query to find correlation between percentageexpenditure (healthcare expenditure) and Lifeexpectancy. Higher healthcare spending might correlate with higher life expectancy.
SELECT
	(COUNT(*) * SUM(xy) - SUM(x) * SUM(y)) / 
    SQRT((COUNT(*) * SUM(xx) - SUM(x) * SUM(x)) * (COUNT(*) * SUM(yy) - SUM(y) * SUM(y))) AS correlation
FROM
(
SELECT
	percentageexpenditure AS x,
    lifeexpectancy AS y,
    percentageexpenditure * lifeexpectancy AS xy,
    percentageexpenditure * percentageexpenditure AS xx,
    lifeexpectancy * lifeexpectancy AS yy
FROM
	worldlifeexpectancy
) AS t;
-- Tương quan giữa percentageexpenditure (healthcare expenditure) và lifeexpectancy là 0.38 - mức tương quan tương đối 
-- Nghĩa là Higer healthcare spending thì life expectancy cũng có xu hướng tăng lên, nhưng mức độ tăng không quá rõ ràng, có thể còn có yếu tố khác ảnh hưởng

-- 12. BMI and Health Indicators: Query to find the correlation between BMI and other health indicators life Lifeexpectancy and AdultMortality. Analyze the impact of BMI on them.
-- Find correlation between BMI and Lifeexpectancy
SELECT
	(COUNT(*) * SUM(xy) - SUM(x) * SUM(y)) /
    SQRT((COUNT(*) * SUM(xx) - SUM(x) * SUM(x)) * (COUNT(*) * SUM(yy) - SUM(y) * SUM(y))) AS correlation
FROM 
(
SELECT
	BMI AS x,
    Lifeexpectancy AS y,
    BMI * Lifeexpectancy AS xy,
    BMI * BMI AS xx,
    Lifeexpectancy * Lifeexpectancy AS yy
FROM
	worldlifeexpectancy
)t1;

-- Tương quan giữa BMI và Lifeexpectancy là 0.57, mối tương quan dương, tương đối giữa hai biến này
-- Điều này có nghĩa là khi BMI tăng, tuổi thọ cũng có xu hướng tăng, nhưng mối quan hệ này không hoàn toàn mạnh mẽ. BMI có liên quan đến tuổi thọ, nhưng không phải là yếu tố duy nhất quyết định tuổi thọ
-- Điều này có thể được giải thích bổi việc: Mặc dù BMI cao có thể liên quan đến nguy cơ mắc các bệnh như tiểu đường, tim mạch, và huyết áp cao, nhưng một số nghiên cứu chỉ ra rằng một BMI vừa phải hoặc cao hơn một chút ở người trưởng thành có thể giúp họ sống lâu hơn.

-- Find correlation between BMI and AdultMortality
SELECT
	(COUNT(*) * SUM(xy) - SUM(x) * SUM(y)) /
    SQRT((COUNT(*) * SUM(xx) - SUM(x) * SUM(x)) * (COUNT(*) * SUM(yy) - SUM(y) * SUM(y))) AS correlation
FROM
(
SELECT
	BMI AS x,
    AdultMortality AS y,
    BMI * AdultMortality AS xy,
    BMI * BMI AS xx,
    AdultMortality * AdultMortality AS yy 
FROM
	worldlifeexpectancy
) t1;

-- Tương quan giữa BMI và AdultMoratlity là -0.38. Mức tương quan âm tương đối yếu
-- Nghĩa là khi BMI tăng (người có xu hướng thừa cân hoặc béo phì) , tỉ lệ AdultMoratlity có xu hướng giảm, nhưng mối quan hệ này không mạnh và còn nhiều yếu tố khác có thể tác động đến tỷ lệ tử vong ở người lớn ngoài BMI
-- Điều này có thể giải thích bởi việc: Mặc dù BMI cao có thể liên quan đến nguy cơ mắc các bệnh như tiểu đường, tim mạch, và huyết áp cao, nhưng một số nghiên cứu cũng chỉ ra rằng BMI vùa phải hoặc cao hơn 1 chút ở người trưởng thành có thể giúp họ sống lâu hơn.

-- 13. GDP and Health Outcomes: Query to analyze how GDP influences health outcomes such as Lifeexpectancy, Adultmortality, and infantdeaths. Compare high GDP and low GDP countries
WITH avg_stats AS (
SELECT
	Country,
    AVG(GDP) AS avg_gdp,
    AVG(Lifeexpectancy) AS avg_lifeexpectancy,
    AVG(AdultMortality) AS avg_adultmortality,
    AVG(infantdeaths) AS avg_infantdeaths
FROM worldlifeexpectancy
GROUP BY Country
HAVING AVG(GDP) <> 0
),
gdp_group AS (
SELECT
	*,
    CASE 
		WHEN avg_gdp < 10000 THEN 'Low'
        WHEN avg_gdp >= 10000 AND avg_gdp < 30000 THEN 'medium'
        ELSE 'high'
	END AS gdp_bucket
FROM
	avg_stats
)
SELECT
	gdp_bucket,
    AVG(avg_lifeexpectancy) AS lifeexpectancy,
    AVG(avg_adultmortality) AS adultmortality,
    AVG(avg_infantdeaths) AS infantdeaths
FROM
	gdp_group
GROUP BY gdp_bucket;

-- Ở các nước có GDP thấp (<10000), tuổi thọ trung bình, số ca tử vong cho người lớn và trẻ em cao hơn hẳn so với các nước có GDP ở mức trung bình và cao.

-- 14. Subgroup Analysis of Lifeexpectancy: Query to find the average Lifeexpectancy for specific subgroups, such as countries in different continents or regions. This can help in identifying regional health disparties

WITH region_table AS (
SELECT
	*,
	 CASE
		-- Châu Á
		WHEN Country IN ('Afghanistan', 'Armenia', 'Azerbaijan', 'Bangladesh', 'Bhutan', 'Brunei Darussalam', 'Cambodia', 
						 'China', 'Democratic People\'s Republic of Korea', 'India', 'Indonesia', 'Islamic Republic of Iran', 
						 'Iraq', 'Israel', 'Japan', 'Jordan', 'Kazakhstan', 'Kuwait', 'Kyrgyzstan', 'Lao People\'s Democratic Republic', 
						 'Lebanon', 'Malaysia', 'Maldives', 'Mongolia', 'Myanmar', 'Nepal', 'Oman', 'Pakistan', 'Philippines', 
						 'Qatar', 'Republic of Korea', 'Saudi Arabia', 'Singapore', 'Sri Lanka', 'Syrian Arab Republic', 
						 'Tajikistan', 'Thailand', 'Timor-Leste', 'Turkmenistan', 'United Arab Emirates', 'Uzbekistan', 'Viet Nam', 'Yemen', 'Georgia', 'Turkey') THEN 'Asia'
		
		-- Châu Âu
		WHEN Country IN ('Albania', 'Armenia', 'Austria', 'Belarus', 'Belgium', 'Bosnia and Herzegovina', 'Bulgaria', 
						 'Croatia', 'Cyprus', 'Czechia', 'Denmark', 'Estonia', 'Finland', 'France', 'Germany', 'Greece', 'Hungary', 
						 'Iceland', 'Ireland', 'Italy', 'Kazakhstan', 'Latvia', 'Lithuania', 'Luxembourg', 'Malta', 'Moldova', 
						 'Montenegro', 'Netherlands', 'North Macedonia', 'Norway', 'Poland', 'Portugal', 'Romania', 
						 'Russian Federation', 'Serbia', 'Slovakia', 'Slovenia', 'Spain', 'Sweden', 'Switzerland', 'Ukraine', 'United Kingdom of Great Britain and Northern Ireland', 'Republic of Moldova', 'The former Yugoslav republic of Macedonia') THEN 'Europe'

		-- Châu Phi
		WHEN Country IN ('Algeria', 'Angola', 'Benin', 'Botswana', 'Burkina Faso', 'Burundi', 'Cabo Verde', 'Cameroon', 
						 'Central African Republic', 'Chad', 'Comoros', 'Congo', 'Democratic Republic of the Congo', 'Djibouti', 
						 'Egypt', 'Equatorial Guinea', 'Eritrea', 'Eswatini', 'Ethiopia', 'Gabon', 'Gambia', 'Ghana', 'Guinea', 
						 'Guinea-Bissau', 'Ivory Coast', 'Kenya', 'Lesotho', 'Liberia', 'Libya', 'Madagascar', 'Malawi', 'Mali', 
						 'Mauritania', 'Mauritius', 'Morocco', 'Mozambique', 'Namibia', 'Niger', 'Nigeria', 'Rwanda', 'Sao Tome and Principe', 
						 'Senegal', 'Seychelles', 'Sierra Leone', 'Somalia', 'South Africa', 'South Sudan', 'Sudan', 'Togo', 'Uganda', 
						 'United Republic of Tanzania', 'Zambia', 'Zimbabwe', 'Côte d\'Ivoire', 'Swaziland', 'Tunisia') THEN 'Africa'
		
		-- Châu Mỹ (Bắc Mỹ và Nam Mỹ)
		WHEN Country IN ('Antigua and Barbuda', 'Argentina', 'Bahamas', 'Barbados', 'Belize', 'Bolivia', 'Brazil', 'Canada', 
						 'Chile', 'Colombia', 'Costa Rica', 'Cuba', 'Dominican Republic', 'Ecuador', 'El Salvador', 'Grenada', 
						 'Guatemala', 'Guyana', 'Haiti', 'Honduras', 'Jamaica', 'Mexico', 'Nicaragua', 'Panama', 'Paraguay', 
						 'Peru', 'Saint Lucia', 'Saint Vincent and the Grenadines', 'Suriname', 'Trinidad and Tobago', 
						 'United States of America', 'Uruguay', 'Venezuela', 'Plurinational State of Bolivia') THEN 'Americas'
		
		-- Châu Đại Dương
		WHEN Country IN ('Australia', 'Fiji', 'Kiribati', 'Micronesia', 'Nauru', 'New Zealand', 
						 'Palau', 'Papua New Guinea', 'Samoa', 'Solomon Islands', 'Tonga', 'Tuvalu', 'Vanuatu', 'Federated States of Micronesia') THEN 'Oceania'
		
		-- Trung Đông (nếu muốn tách riêng khu vực này)
		WHEN Country IN ('Bahrain', 'Iraq', 'Israel', 'Jordan', 'Kuwait', 'Lebanon', 'Oman', 'Qatar', 'Saudi Arabia', 
						 'Syrian Arab Republic', 'United Arab Emirates', 'Yemen') THEN 'Middle East'
	  END AS Region
FROM 
worldlifeexpectancy
) 
SELECT region, AVG(lifeexpectancy) FROM region_table
GROUP BY region
ORDER BY AVG(lifeexpectancy) DESC;

-- Tuổi thọ trung bình ở Africa là thấp nhất với 58.61 --> còn lại đều trên 70 (Europe cao nhất với 77.4)

