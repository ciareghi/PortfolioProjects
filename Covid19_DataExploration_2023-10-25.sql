-- Selecting Data that I'm going to be using

SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1, 2


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract Covid in Italy

SELECT Location, Date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like 'Italy'
WHERE continent is not null
ORDER BY 1, 2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid in Italy

SELECT Location, Date, population, total_cases, (CAST(total_cases as float) / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location like 'Italy'
WHERE continent is not null
ORDER BY 1, 2


-- Looking at Countries with highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, (CONVERT(float, MAX(total_cases) / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC


-- Showing the Countries with Highest Death Count per Population

SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount DESC


-- BY CONTINENT

-- Showing the continents with the highest death count per population

SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null AND Location not like '%income%' 
  and location not like '%world%' 
  and location not like '%union%'
GROUP BY location
ORDER BY TotalDeathCount DESC

SELECT Continent, MAX(cast(total_deaths as int)) AS TotalDeathCount -- this code shows faulty results, previous one is better.
FROM PortfolioProject..CovidDeaths
WHERE continent is not null 
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- BY COUNTRY INCOME

SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null AND Location like '%income%'
GROUP BY location
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS

-- Overall DeathPercentage across the world

SELECT SUM(new_cases) TotalCases, SUM(new_deaths) TotalDeaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2


-- DeathPercentage across the world by date

SELECT date, SUM(new_cases) TotalCases, SUM(new_deaths) TotalDeaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2




/*
-- COVID VACCINATIONS
*/

SELECT *
FROM PortfolioProject..CovidVaccinations


-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  , SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
  --, (RollingPeopleVaccinated/population)*100 how do I do this? A couple of options below 
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location 
  AND dea.date = vac.date
WHERE dea.continent is not null
--  AND dea.location = 'Canada' //used to check some values
ORDER BY 2, 3


-- Option 1: USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  , SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location 
  AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as RollingPercentVaccinated
FROM PopvsVac
ORDER BY 2, 3


-- Option 2: TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  , SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location 
  AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/population)*100 as RollingPercentVaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2, 3



-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  , SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
  ON dea.location = vac.location 
  AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2, 3

CREATE VIEW ContinentDeathCount AS
SELECT Location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null AND Location not like '%income%' 
  and location not like '%world%' 
  and location not like '%union%'
GROUP BY location

CREATE VIEW PercentPopulationInfected AS
SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, (CONVERT(float, MAX(total_cases) / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY Location, Population