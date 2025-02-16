-- Check the original data
SELECT TOP 10 *
FROM dbo.CrimeDataLA

-- START CLEAN DATA
-- Change data type to DATE on date columns 
-- Try if I can conver the data type
SELECT Date_Reported, TRY_CONVERT(DATE, Date_Reported) AS DateConverted
FROM dbo.CrimeDataLA;

-- Now change the data type
UPDATE dbo.CrimeDataLA
SET Date_Reported = CAST(Date_Reported AS DATE),
	Date_Occurred = CAST(Date_Occurred AS DATE);

ALTER TABLE dbo.CrimeDataLA
ALTER COLUMN Date_Reported DATE;

ALTER TABLE dbo.CrimeDataLA
ALTER COLUMN Date_Occurred DATE;

-- Create a new column with times in correct format and type
SELECT Time_Occurred,
       CAST(FORMAT(Time_Occurred / 100, '00') + ':' + FORMAT(Time_Occurred % 100, '00') AS TIME) AS New_Time
FROM dbo.CrimeDataLA;

ALTER TABLE dbo.CrimeDataLA
ADD Time_Occ_Correct TIME;

UPDATE dbo.CrimeDataLA
SET Time_Occ_Correct = CAST(FORMAT(Time_Occurred / 100, '00') + ':' + FORMAT(Time_Occurred % 100, '00') AS TIME);

-- Create a new column with age ranges
-- Check what crimes are committed on 2 year old children
SELECT DISTINCT(Crime_Description)
FROM dbo.CrimeDataLA
WHERE Victim_Age = 2
ORDER BY Crime_Description

-- Check what crimes and their percentajes are commited on children under 1 year of age
SELECT Crime_Description, (COUNT(Crime_Description) * 100.0 / SUM(COUNT(Crime_Description)) OVER()) AS Percentaje_Crimes
FROM dbo.CrimeDataLA
WHERE Victim_Age < 1
GROUP BY Crime_Description
ORDER BY Percentaje_Crimes DESC

-- Now create the age ranges column
ALTER TABLE dbo.CrimeDataLA
ADD Age_Range VARCHAR(50);

UPDATE dbo.CrimeDataLA
SET Age_Range = CASE 
    WHEN Victim_Age BETWEEN 1 AND 17 THEN '1-17 (Child/Teenager)'
    WHEN Victim_Age BETWEEN 18 AND 29 THEN '18-29 (Young Adult)'
    WHEN Victim_Age BETWEEN 30 AND 60 THEN '30-60 (Adult)'
    WHEN Victim_Age >= 60 THEN '60+ (Senior)'
    ELSE 'Unknown'
END;

-- Check victims sex and clean the data with a new column
SELECT DISTINCT(Victim_Sex), COUNT(Victim_Sex)
FROM dbo.CrimeDataLA
GROUP BY Victim_Sex

ALTER TABLE dbo.CrimeDataLA
ADD Victim_Sex_Description VARCHAR(100);

UPDATE dbo.CrimeDataLA
SET Victim_Sex_Description = CASE 
    WHEN Victim_Sex = 'M' THEN 'Male'
    WHEN Victim_Sex = 'F' THEN 'Female'
    ELSE 'Unknown' 
END;

-- Check victims ethnicity and clean the data with a new column
SELECT DISTINCT(Victim_Ethnicity), COUNT(Victim_Ethnicity)
FROM dbo.CrimeDataLA
GROUP BY Victim_Ethnicity
ORDER BY Victim_Ethnicity

ALTER TABLE dbo.CrimeDataLA
ADD Victim_Ethnicity_Description VARCHAR(100);

UPDATE dbo.CrimeDataLA
SET Victim_Ethnicity_Description = CASE 
    WHEN Victim_Ethnicity = 'A' THEN 'Other Asian'
    WHEN Victim_Ethnicity = 'B' THEN 'Black'
	WHEN Victim_Ethnicity = 'C' THEN 'Chinese'
    WHEN Victim_Ethnicity = 'D' THEN 'Cambodian'
	WHEN Victim_Ethnicity = 'F' THEN 'Filipino'
    WHEN Victim_Ethnicity = 'G' THEN 'Guamanian'
	WHEN Victim_Ethnicity = 'H' THEN 'Hispanic'
    WHEN Victim_Ethnicity = 'I' THEN 'American Indian'
	WHEN Victim_Ethnicity = 'J' THEN 'Japanese'
    WHEN Victim_Ethnicity = 'K' THEN 'Korean'
	WHEN Victim_Ethnicity = 'L' THEN 'Laotian'
	WHEN Victim_Ethnicity = 'O' THEN 'Other'
    WHEN Victim_Ethnicity = 'P' THEN 'Pacific Islander'
	WHEN Victim_Ethnicity = 'S' THEN 'Samoan'
	WHEN Victim_Ethnicity = 'U' THEN 'Hawaiian'
    WHEN Victim_Ethnicity = 'V' THEN 'Vietnamese'
	WHEN Victim_Ethnicity = 'W' THEN 'White'
	WHEN Victim_Ethnicity = 'Z' THEN 'Asian Indian'
    ELSE 'Unknown' 
END;

-- Replace 3 columns that may contain NULL values with one without them
ALTER TABLE dbo.CrimeDataLA
ADD Additional_Crimes VARCHAR(100);

UPDATE dbo.CrimeDataLA
SET Additional_Crimes = 
    CASE WHEN Crime_Code_2 IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN Crime_Code_3 IS NOT NULL THEN 1 ELSE 0 END +
    CASE WHEN Crime_Code_4 IS NOT NULL THEN 1 ELSE 0 END;

-- Check if I can do a SELF JOIN and clean the data with a new column
SELECT Weapon_Description, Weapon_Code
FROM dbo.CrimeDataLA
WHERE Weapon_Description IS NULL

ALTER TABLE dbo.CrimeDataLA
ADD Weapon_Correct_Description VARCHAR(100);

UPDATE dbo.CrimeDataLA
SET Weapon_Correct_Description = COALESCE(Weapon_Description, 'UNKNOWN WEAPON/OTHER WEAPON');

-- Create a new column with clean data about Status_Correct
ALTER TABLE dbo.CrimeDataLA
ADD Status_Correct_Description NVARCHAR(255);

UPDATE dbo.CrimeDataLA
SET Status_Correct_Description = CASE 
                        WHEN Status_Description = 'Juv Arrest' THEN 'Juvenile Arrest'
						WHEN Status_Description = 'Juv Other' THEN 'Juvenile Other'
                        WHEN Status_Description = 'UNK' THEN 'Unknown'
						WHEN Status_Description = 'Invest Cont' THEN 'Investigation Continues'
                        ELSE Status_Description
                    END;

-- Check if there are any duplicates (there aren't)
WITH Duplicates AS (
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY File_number, Date_Occurred, Latitude ORDER BY File_number) AS number_row
    FROM dbo.CrimeDataLA
)
SELECT File_number, number_row
FROM Duplicates
WHERE number_row > 1;

-- END CLEAN DATA

-- Check final clean data
SELECT TOP 10 *
FROM dbo.CrimeDataLA



-- START EXPLORATION DATA
-- Check up to what date in 2024 we have data
SELECT Date_Occurred, MONTH(Date_Occurred)
FROM dbo.CrimeDataLA
WHERE YEAR(Date_Occurred) = 2024
ORDER BY Date_Occurred DESC

-- Use the information to compare the crimes per year and per victim sex
SELECT YEAR(Date_Occurred) AS Year_Occurred, Victim_Sex_Description, COUNT(*) AS Crimes_Per_Year
FROM dbo.CrimeDataLA
WHERE MONTH(Date_Occurred) <= 9
GROUP BY YEAR(Date_Occurred), Victim_Sex_Description
ORDER BY Victim_Sex_Description, YEAR(Date_Occurred)


-- Check the Top 5 areas with more crimes
SELECT Area_Name, COUNT(*) AS Crimes_per_Area
FROM dbo.CrimeDataLA
GROUP BY Area_Name
HAVING COUNT(*) > 50000
ORDER BY Crimes_per_Area DESC


-- Look for Top 3 crimes per area
WITH Top_Crimes_Area AS (
	SELECT 
		Area_Name, 
		Crime_Description, 
		COUNT(*) AS Total_Crimes,
		RANK() OVER(PARTITION BY Area_Name ORDER BY COUNT(*) DESC) AS Ranking
	FROM 
		dbo.CrimeDataLA
	GROUP BY 
		Area_Name, Crime_Description
)
SELECT Area_Name, Crime_Description, Total_Crimes, Ranking
FROM Top_Crimes_Area
WHERE Ranking < 4
ORDER BY Area_Name, Ranking


-- Check the number of crimes by ethnicity, their percentaje of the total and cumulative
WITH Percentaje_Eth AS (
	SELECT 
		Victim_Ethnicity_Description,
		COUNT(*) AS Number_Crimes,
		CAST(100.0 * COUNT(*)/SUM(COUNT(*)) OVER() AS DECIMAL(10,4)) AS Percentaje_Crimes_Eth
	FROM dbo.CrimeDataLA
	GROUP BY Victim_Ethnicity_Description
)
SELECT 
	Victim_Ethnicity_Description,
	Number_Crimes,
	Percentaje_Crimes_Eth,
	CAST(SUM(Percentaje_Crimes_Eth) OVER(ORDER BY Number_Crimes DESC) AS DECIMAL(10,4)) AS Acumulative_Percentaje
FROM Percentaje_Eth
WHERE Victim_Ethnicity_Description <> 'Unknown'
ORDER BY Percentaje_Crimes_Eth DESC


-- Find the growth of crimes with respect the previous year by age range
WITH AgeRangeCrimes AS (
    SELECT 
        YEAR(Date_Occurred) AS Year_Occurred,
        Age_Range, 
        COUNT(*) AS Number_Crimes
    FROM 
        dbo.CrimeDataLA
    GROUP BY 
        YEAR(Date_Occurred), Age_Range
),
CrimesGrowth AS (
    SELECT 
        Year_Occurred,
        Age_Range,
        Number_Crimes,
        LAG(Number_Crimes) OVER(PARTITION BY Age_Range ORDER BY Year_Occurred) AS Last_Number_Crimes,
        Number_Crimes - LAG(Number_Crimes) OVER(PARTITION BY Age_Range ORDER BY Year_Occurred) AS Crime_Growth,
        CASE 
            WHEN LAG(Number_Crimes) OVER(PARTITION BY Age_Range ORDER BY Year_Occurred) = 0 THEN NULL
            ELSE 
                CAST(
                    (Number_Crimes - LAG(Number_Crimes) OVER(PARTITION BY Age_Range ORDER BY Year_Occurred)) 
                    * 100.0 / LAG(Number_Crimes) OVER(PARTITION BY Age_Range ORDER BY Year_Occurred) AS DECIMAL(10,2)
                )
        END AS Percentaje_Growth
    FROM 
        AgeRangeCrimes
)
SELECT 
    Year_Occurred,
    Age_Range,
    Number_Crimes,
    Last_Number_Crimes,
    Crime_Growth,
    Percentaje_Growth
FROM 
    CrimesGrowth
WHERE Year_Occurred <> 2024
ORDER BY 
    Age_Range, Year_Occurred;

SELECT TOP 10 *
FROM dbo.CrimeDataLA

CREATE VIEW vw_CrimesLA AS
SELECT
	File_Number,
	Date_Reported,
	Date_Occurred,
	Time_Occ_Correct,
	Area_Name,
	Crime_Description,
	Age_Range,
	Victim_Ethnicity_Description,
	Victim_Sex_Description,
	Status_Correct_Description,
	Weapon_Correct_Description,
	Additional_Crimes,
	dbo.CrimeDataLA.Location,
	Latitude,
	Longitude
FROM dbo.CrimeDataLA;