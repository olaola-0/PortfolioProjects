/* Covid-19 data exploration 
Skills implemented: Data type conversion, Datetime abstraction, Aggregate funtions, Joins, 
					CTEs, Temp Tables, Creating Views, Windwo Functions. 
*/


-- Query to Select Non-Null Continent Records from CovidDeaths:
-- Selects all columns from the CovidDeaths table where the continent column is not null, 
-- ordering by the third and fourth columns. 
-- This query filters out rows that don't relate to specific continents,.
-- That is, excluding global or regional summaries.
SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- Query to Select Records from CovidVaccinations:
-- Retrieves all columns from the CovidVaccinations table, ordering the results by the third and fourth columns. 
-- This query aims to organize vaccination data and excludes global or regional summaries..
SELECT *
FROM CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3, 4

-- Selecting Specific Columns from CovidDeaths:
-- Extracts key data columns from the CovidDeaths table, including location, date, cases, deaths, and population,
-- ordered by location and date. 
-- This query is useful for a focused analysis on the spread and impact of COVID-19.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2

-- Mortality Percentage in Nigeria and Sweden Post-2023:
-- Calculates the mortality percentage (total deaths divided by total cases) for Nigeria and Sweden 
-- for years after 2023, ordering by location and date. 
-- This query highlights the severity of COVID-19 in these countries in recent years.
SELECT location, date, total_cases, total_deaths, 
	  (CONVERT(FLOAT, total_deaths) / CONVERT(FLOAT, total_cases))*100 mortality_percentage
FROM CovidDeaths
WHERE 
	location IN ('Nigeria', 'Sweden')  
	AND YEAR(date) > 2023
ORDER BY 1, 2

-- Infection Percentage by Population in Nigeria and Sweden Post-2023:
-- Computes the percentage of the population infected by COVID-19 in Nigeria and Sweden after 2023, 
-- providing insights into the pandemic's reach within these populations.
SELECT location, date, total_cases, population, 
	  (CONVERT(FLOAT, total_cases) / population)*100 infected_percentage
FROM CovidDeaths
WHERE 
	location IN ('Nigeria', 'Sweden')  
	AND YEAR(date) > 2023
ORDER BY 1, 2


-- Countries with the Highest Infection Count by Population:
-- Identifies the locations with the highest count of COVID-19 cases and calculates what percentage of each 
-- location's population was infected, ordered by this percentage. 
-- This query reveals which areas were most affected relative to their population size.
SELECT location, population, MAX(total_cases) highest_infection_count,
	  MAX(CONVERT(FLOAT, total_cases) / population)*100 population_infected_percentage
FROM CovidDeaths
GROUP BY location, population
ORDER BY population_infected_percentage DESC


-- Highest Covid-19 Death Count by Country and Continent:
-- Finds the maximum total deaths recorded in the CovidDeaths table for each location where the continent is 
-- specified, indicating the hardest-hit areas. 
SELECT location, MAX(CAST(total_deaths AS int)) total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- This query performs a similar analysis for locations classified differently
-- Excluding specific income groups and regions.
SELECT location, MAX(CAST(total_deaths AS int)) total_death_count
FROM CovidDeaths
WHERE continent IS NULL 
AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY total_death_count DESC



-- Global Covid-19 Numbers:
-- Aggregates new cases and new deaths globally (excluding rows without a specified continent) to compute 
-- total figures and the overall death percentage. 
-- This query provides a high-level view of the pandemic's impact.
SELECT SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, SUM(new_deaths)/SUM(new_cases)*100 death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2



-- TOTAL POPULATION vs. VACCINATIONS ANALYSIS:


-- Joins CovidDeaths and CovidVaccinations tables to match locations and dates, 
-- selecting data on population and new vaccinations for areas with specified continents. 
-- This analysis helps understand vaccination progress relative to population size.
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations
FROM CovidDeaths CD
JOIN CovidVaccinations CV
	ON
	CD.location = CV.location 
	AND CD.date = CV.date
WHERE CD.continent IS NOT NULL


-- The query selects the continent, location, date, population, and new vaccinations for each record.
-- It uses a window function to calculate a running total of new vaccinations for each location, 
-- ordered by location and date. The ISNULL function ensures that null values in new_vaccinations are treated 
-- as 0, preventing null results in the running total. The CONVERT function is used to ensure that the 
-- calculation handles large numbers by converting the new_vaccinations column to BIGINT.

-- The result provides an insight into the cumulative number of vaccinations administered in each location 
-- over time, set against the backdrop of the population size and the progression of dates. 
-- This allows for an assessment of vaccination efforts within different continents and locations, showing 
-- how vaccination numbers have increased.
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
    SUM(CONVERT(BIGINT, ISNULL(CV.new_vaccinations, 0))) 
	OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) rolling_vaccination_count
FROM CovidDeaths CD
JOIN CovidVaccinations CV
    ON CD.location = CV.location 
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL



--                                        CTE:
-- The CTE, PopvsVac, prepares a dataset that includes the continent, location, date, population, 
-- new vaccinations for each day, and a rolling vaccination count for each location. The rolling count is 
-- calculated using a window function that sums the new vaccinations (converting nulls to 0 for accurate summation) partitioned by location and ordered by date. 
-- This structure allows tracking the cumulative number of vaccinations over time for each location.

-- After preparing the dataset with the CTE, the main query selects all columns from the CTE and calculates
-- an additional column, Vaccination_Percentage. This column represents the percentage of the population that has
-- been vaccinated, computed by dividing the rolling vaccination count by the population and multiplying by 100 to convert it to a percentage.

-- The WHERE clause in the main query filters the results to show only records for "Nigeria" where new 
-- vaccinations data is available (i.e., not null). This focus ensures the analysis is relevant to vaccination 
-- efforts in Nigeria, providing insights into how the vaccination campaign is progressing in terms of reaching the population.

-- This query highlights the use of CTEs for organizing complex calculations and aggregations, making 
-- the final SELECT statement simpler and more focused on the analysis of interest. It's particularly useful
-- for public health analysis, enabling a detailed look at vaccination coverage over time within a specific location.
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Rolling_Vaccination_Count)
AS
(
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
    SUM(CONVERT(BIGINT, ISNULL(CV.new_vaccinations, 0))) 
    OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) AS rolling_vaccination_count
FROM CovidDeaths CD
JOIN CovidVaccinations CV
    ON CD.location = CV.location 
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL
)
SELECT *, 
    (Rolling_Vaccination_Count / Population) * 100 AS Vaccination_Percentage
FROM PopvsVac
WHERE Location = 'Nigeria' AND New_Vaccinations IS NOT NULL



--										TEMP TABLE:
DROP TABLE IF EXISTS #Population_Vaccination_Percentage
CREATE TABLE #Population_Vaccination_Percentage
(Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population FLOAT,
New_Vaccinations FLOAT,
Rolling_Vaccination_Count FLOAT
)

INSERT INTO #Population_Vaccination_Percentage
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
    SUM(CONVERT(BIGINT, ISNULL(CV.new_vaccinations, 0))) 
	OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) rolling_vaccination_count
FROM CovidDeaths CD
JOIN CovidVaccinations CV
    ON CD.location = CV.location 
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL



--										VIEWS:
DROP VIEW IF EXISTS Population_Vaccination_Percentage;
GO
CREATE VIEW Population_Vaccination_Percentage AS 
SELECT CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
    SUM(CONVERT(BIGINT, ISNULL(CV.new_vaccinations, 0))) 
	OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date) rolling_vaccination_count
FROM CovidDeaths CD
JOIN CovidVaccinations CV
    ON CD.location = CV.location 
    AND CD.date = CV.date
WHERE CD.continent IS NOT NULL