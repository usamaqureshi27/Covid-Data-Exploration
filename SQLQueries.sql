INSERT INTO CovidDeaths
SELECT *
FROM [Portfolio Project].[dbo].[CovidDeaths]

SELECT *
FROM CovidDeaths

INSERT INTO CovidVaccinations
SELECT *
FROM [Portfolio Project].[dbo].[CovidVaccinations]

SELECT *
FROM CovidVaccinations
------------------------------

-- Data Cleaning --

-- Standardize date

Select date
FROM CovidDeaths

SELECT date, CONVERT (DATE, date)
FROM CovidDeaths

ALTER TABLE CovidDeaths
ADD DateConverted Date

UPDATE CovidDeaths
SET DateConverted = CONVERT(DATE, date)

Select DateConverted 
FROM CovidDeaths

ALTER TABLE CovidVaccinations
ADD DateConverted Date

UPDATE CovidVaccinations
SET DateConverted = CONVERT(DATE, date)

Select DateConverted 
FROM CovidVaccinations

-------
SELECT *
, ROW_NUMBER () OVER (PARTITION BY  date, location  ORDER BY location) as row_num
FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY date

-- Remove Duplicate with CTE
WITH CTE AS (
	SELECT *, 
	ROW_NUMBER () OVER 
	(PARTITION BY location, DateConverted  ORDER BY location, DateConverted ) AS row_num
FROM CovidDeaths
)
SELECT *
FROM CTE
WHERE row_num > 1

-- no duplicate
-- but if there are duplicate change select with delete above
 
------ 
--Delete unused columns

 ALTER TABLE CovidDeaths
 DROP COlUMN Date

 ALTER TABLE CovidVaccinations
 DROP COlUMN Date

ALTER TABLE CovidDeaths
DROP COLUMN total_cases_per_million,new_cases_per_million,
 new_cases_smoothed_per_million,total_deaths_per_million,
 new_deaths_per_million,new_deaths_smoothed_per_million,
 reproduction_rate,icu_patients,icu_patients_per_million,
 hosp_patients,hosp_patients_per_million,weekly_icu_admissions,
 weekly_icu_admissions_per_million,weekly_hosp_admissions,
 weekly_hosp_admissions_per_million

ALTER TABLE CovidVaccinations
DROP COLUMN handwashing_facilities, hospital_beds_per_thousand,
	life_expectancy,human_development_index, excess_mortality_cumulative_absolute, excess_mortality_cumulative,excess_mortality,
	excess_mortality_cumulative_per_million,total_boosters,new_vaccinations,
	new_vaccinations_smoothed, total_vaccinations_per_hundred,people_vaccinated_per_hundred,
	people_fully_vaccinated_per_hundred,total_boosters_per_hundred,new_vaccinations_smoothed_per_million,
	new_people_vaccinated_smoothed,new_people_vaccinated_smoothed_per_hundred,stringency_index,
	population_density,median_age,aged_65_older,aged_70_older

------------------------------
-- Data Analysis --

SELECT *
FROM CovidDeaths
ORDER BY 3,dateconverted

SELECT *
FROM CovidVaccinations
ORDER BY 3, dateconverted

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 As DeathPercentage
FROM CovidDeaths
ORDER BY 1,2

-----
-- Death Rate

ALTER TABLE CovidDeaths 
ADD DeathPercentage FLOAT 

UPDATE CovidDeaths
SET DeathPercentage = (total_deaths/total_cases) * 100

-----
-- Cases Percentage

ALTER TABLE CovidDeaths 
ADD CasesPercentage FLOAT

UPDATE CovidDeaths
SET CasesPercentage = (total_cases/population) * 100

-----
-- Highest Infection Count

SELECT location, Population, MAX( total_cases) AS HighestInfectionCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, Population
ORDER BY HighestInfectionCount DESC


-----
-- Percenatage Population Cases

SELECT location,Population , MAX( total_cases) AS HighestInfectionCount, 
ROUND(MAX(total_cases/ population)*100 , 2) AS PercenatagePopulationCases
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location , Population
ORDER BY PercenatagePopulationCases DESC


ALTER TABLE CovidDeaths 
ADD PercenatagePopulationCases FLOAT

UPDATE CovidDeaths 
SET PercenatagePopulationCases = (total_cases/ population)*100
WHERE continent IS NOT NULL

SELECT location, total_cases, population, PercenatagePopulationCases
FROM CovidDeaths
ORDER BY PercenatagePopulationCases DESC

-----
-- Highest Death Count

SELECT location, Population, MAX( total_deaths) AS HighestDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, Population
ORDER BY HighestDeathCount DESC

-----
-- Percenatage Population Death

SELECT location, Population, MAX( total_deaths) AS HighestDeathCount, 
ROUND(MAX(total_deaths/ population)*100, 2) AS PercenatagePopulationDeath
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, Population
ORDER BY PercenatagePopulationDeath DESC


ALTER TABLE CovidDeaths 
ADD PercenatagePopulationDeath FLOAT

UPDATE CovidDeaths
SET PercenatagePopulationDeath = (total_deaths/ population)*100
WHERE continent IS NOT NULL

-----
-- Continent Cases Percentage

SELECT continent, ROUND(MAX(total_cases/population) * 100, 2) AS ContinentCasesPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY ContinentCasesPercentage DESC 


ALTER TABLE CovidDeaths 
ADD ContinentCasesPercentage FLOAT

UPDATE CovidDeaths
SET ContinentCasesPercentage = (total_cases/population) * 100
WHERE continent IS NOT NULL

-----
-- Continent Death Percentage

SELECT continent,  MAX( total_deaths) AS HighestDeathCount , 
ROUND(MAX(total_deaths/population)*100,2) AS ContinentDeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY ContinentDeathPercentage DESC 


ALTER TABLE CovidDeaths 
ADD ContinentDeathPercentage FLOAT

UPDATE CovidDeaths
SET ContinentDeathPercentage = (total_deaths/population)*100
WHERE continent IS NOT NULL

SELECT continent, total_cases, population, ContinentDeathPercentage
FROM CovidDeaths
ORDER BY ContinentDeathPercentage DESC


-----
-- Death Rate Globally

SET ANSI_WARNINGS OFF
GO

SELECT DateConverted, SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, 
SUM(new_deaths)/NULLIF (SUM (new_cases),0) * 100 AS DeathRateGlobally
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY DateConverted
ORDER BY 1

ALTER TABLE CovidDeaths 
ADD DeathRateGlobally FLOAT

UPDATE CovidDeaths
SET DeathRateGlobally = new_deaths/ NULLIF ((new_cases),0) * 100
WHERE continent IS NOT NULL

----

SELECT *
FROM CovidDeaths AS dea
JOIN CovidVaccinations AS vac
ON dea.location = vac.location 
AND dea.DateConverted = vac.DateConverted

------
-- Vaccination Count
SELECT dea.continent, dea.location, dea.dateconverted, dea.population, vac.new_vaccinations
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.dateconverted = vac.dateconverted
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-------
-- Rolling People Vaccinated

SELECT dea.continent, dea.location, dea.dateconverted, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.dateconverted) AS RollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.dateconverted = vac.dateconverted
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


----
-- Percentage Rolling PeopleVaccinated

-- USE CTE

WITH popvsvac (continent, location, dateconverted, population , new_vaccinations, RollingPeopleVaccinated) AS
(
Select dea.continent, dea.location, dea.dateconverted, dea.population , vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS bigint)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.dateconverted) AS RollingPeopleVaccinated
From coviddeaths dea
JOIN covidvaccinations vac
	ON dea.location = vac.location
	AND dea.dateconverted= vac.dateconverted
WHERE dea.continent is not NULL
)

SELECT * , (RollingPeopleVaccinated/population)*100 AS PercentageRollingPeopleVaccinated
FROM popvsvac

-- USE TEMP Table

--CREATE TABLE #PercentPopulationVaccinated

--(continent nvarchar(255), location nvarchar (255) , 
--dateconverted datetime, population numeric, 
--new_vaccinations numeric, RollingPeopleVaccinated numeric)

--INSERT INTO #PercentPopulationVaccinated
--SELECT dea.continent, dea.location, dea.dateconverted, dea.population , vac.new_vaccinations,
--SUM(CAST(vac.new_vaccinations AS bigint)) 
--OVER (PARTITION BY dea.location ORDER BY dea.location, dea.dateconverted) AS RollingPeopleVaccinated
--From coviddeaths dea
--JOIN covidvaccinations vac
--	ON dea.location = vac.location
--	AND dea.dateconverted= vac.dateconverted
--WHERE dea.continent IS NOT NULL

--SELECT * , (RollingPeopleVaccinated/population)*100 AS PercentageRollingPeopleVaccinated
--FROM #PercentPopulationVaccinated