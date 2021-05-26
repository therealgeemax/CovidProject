--Explore Data
SELECT *
FROM dbo.CovidData 
WHERE Continent IS NOT NULL 
ORDER BY Total_cases

SELECT *
FROM dbo.CovidDeaths 
WHERE Continent IS NOT NULL 
ORDER BY Total_cases

SELECT *
FROM dbo.CovidVaccinations 
WHERE Continent IS NOT NULL 
ORDER BY Total_cases

--Total Cases vs Total Deaths UK
SELECT Location, Date, total_cases, Total_deaths, (Total_deaths/Total_cases) * 100 as DeathPercentage
FROM master.dbo.CovidData 
WHERE Location = 'United Kingdom' 
ORDER BY Location, Date

--Total Cases vs Total Deaths ZA
SELECT Location, Date, total_cases, Total_deaths, (Total_deaths/Total_cases) * 100 as DeathPercentage
FROM master.dbo.CovidData 
WHERE Location = 'South Africa'
ORDER BY Location, Date

--Total Cases vs Population UK
SELECT Location, Date, Population, total_cases, (Total_cases/Population) * 100 as ContractionPercentage
FROM master.dbo.CovidData 
WHERE Location = 'United Kingdom'
ORDER BY Location, Date

--Total Cases vs Population ZA
SELECT Location, Date, Population, total_cases, (Total_cases/Population) * 100 as ContractionPercentage
FROM master.dbo.CovidData 
WHERE Location = 'South Africa'
ORDER BY Location, Date

--Highest Infection rate compared to Population
SELECT Location, Population, Max(total_cases) AS HighestInfectionCount, MAX((Total_cases/Population)) * 100 as PercentPopulationInfected
FROM master.dbo.CovidData 
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

--Highest Deaths per Country
SELECT Location, Max(Cast(total_deaths AS int)) AS TotalDeathCount
FROM master.dbo.CovidData 
WHERE Continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC

--Showing continents with highest death count per population
SELECT Continent, Max(cast(Total_Deaths AS int)) AS TotalDeathCount
From dbo.CovidData 
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC

--Death Percentage per Day
SELECT date, Sum(new_cases) AS TotalCases, Sum(cast(new_deaths AS int)) AS TotalDeaths, (Sum(cast(new_deaths AS int))/Sum(new_cases)) * 100 as DeathPercentage
FROM dbo.CovidData 
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY date 

--Total Death Percentage per Day
SELECT Sum(new_cases) AS TotalCases, Sum(cast(new_deaths AS int)) AS TotalDeaths, (Sum(cast(new_deaths AS int))/Sum(new_cases)) * 100 as DeathPercentage
FROM dbo.CovidData 
WHERE continent IS NOT NULL

-- Highest Death Percentage day
SELECT date, Sum(new_cases) AS TotalCases, Sum(cast(new_deaths AS int)) AS TotalDeaths, (Sum(cast(new_deaths AS int))/Sum(new_cases)) * 100 as DeathPercentage
FROM dbo.CovidData 
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY DeathPercentage DESC

-- Highest Deaths on a day
SELECT date, Sum(new_cases) AS TotalCases, Sum(cast(new_deaths AS int)) AS TotalDeaths, (Sum(cast(new_deaths AS int))/Sum(new_cases)) * 100 as DeathPercentage
FROM dbo.CovidData 
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY TotalDeaths DESC
cv.continent, cv.location, cv.date, cv.population, cv.new_vaccinations, Sum(cast(cv.new_vaccinations AS INT)) OVER (PARTITION BY cv.location ORDER BY cv.location, cv.date)

--Total Population vs Vaccinations
SELECT Continent, Location, date, population, new_vaccinations 
FROM master.dbo.CovidData
WHERE continent IS NOT NULL
ORDER BY Location, date 

--Total Population vs Vaccinations
SELECT Continent, Location, date, population, new_vaccinations, Sum(convert(int,New_vaccinations)) OVER (PARTITION BY Location ORDER BY Location, date)  
FROM master.dbo.CovidData
WHERE continent IS NOT NULL
ORDER BY Location, date 

--Total Population vs Vaccinations
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, Sum(Convert(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.[date]) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths cd JOIN dbo.CovidVaccinations cv ON cd.location = cv.location AND cd.[date] = cv.[date]
WHERE cd.continent IS NOT NULL
ORDER BY 2,3

--USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, Sum(Convert(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.[date]) AS RollingPeopleVaccinated
	FROM dbo.CovidDeaths cd JOIN dbo.CovidVaccinations cv ON cd.location = cv.location AND cd.[date] = cv.[date]
	WHERE cd.continent IS NOT NULL
	--ORDER BY 2,3
)

	SELECT *, (pv.RollingPeopleVaccinated / pv.Population) * 100 AS PercentVaccinatedRunningTotal
	FROM PopvsVac pv

--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated --Dropping temp table if it exists.
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
	SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, Sum(Convert(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.[date]) AS RollingPeopleVaccinated
	FROM dbo.CovidDeaths cd JOIN dbo.CovidVaccinations cv ON cd.location = cv.location AND cd.[date] = cv.[date]
	WHERE cd.continent IS NOT NULL

SELECT *, (ppv.RollingPeopleVaccinated / ppv.Population) * 100 AS PercentVaccinatedRunningTotal
FROM #PercentPopulationVaccinated ppv

--Create View
CREATE VIEW PercentPopulationVaccinated AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, Sum(Convert(int, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.[date]) AS RollingPeopleVaccinated
FROM dbo.CovidDeaths cd 
	JOIN dbo.CovidVaccinations cv 
	ON cd.location = cv.location 
	AND cd.[date] = cv.[date]
WHERE cd.continent IS NOT NULL
--ORDER BY 2,3