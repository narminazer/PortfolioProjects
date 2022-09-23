SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..covid_deaths
ORDER BY 1,2 

SELECT *
FROM PortfolioProject..covid_deaths
WHERE continent is not null
order by 3,4

--Looking at total cases vs total deaths

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..covid_deaths
WHERE location = 'United Kingdom'
ORDER BY 1,2 

--Looking at total cases vs population
--Shows what % of pupulation got covid
SELECT Location, date, total_cases, Population, (total_cases/population)*100 as DeathPercentage
FROM PortfolioProject..covid_deaths
WHERE location = 'United Kingdom'
ORDER BY 1,2 

--Looking at countries with highest infection rate compared to population
SELECT location, population,MAX(total_cases) as highest_infection_count, 
	MAX((total_cases/population))*100 
	as percent_population_infected
FROM PortfolioProject..covid_deaths
GROUP BY location, population
ORDER BY percent_population_infected desc

--Looking at countries with highsest death count per population
-- there is a problem of location being an entire continent
SELECT location, population, MAX(cast(total_deaths as int)) as highest_death_count
FROM PortfolioProject..covid_deaths
WHERE continent is not null
GROUP BY location, population
ORDER BY highest_death_count desc

--lets see where location is also written as continent
SELECT location, MAX(cast(total_deaths as int)) as highest_death_count
FROM PortfolioProject..covid_deaths
WHERE continent is null
GROUP BY location
ORDER BY highest_death_count desc

--let's break things down by continent

--showing continents with the highest death rates
SELECT continent, MAX(cast(total_deaths as int)) as highest_death_count
FROM PortfolioProject..covid_deaths
WHERE continent is not null
GROUP BY continent
ORDER BY highest_death_count desc


--global numbers
-- death percentage across the world by date
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..covid_deaths
--WHERE location = 'United Kingdom'
WHERE continent is  not null
GROUP BY date
ORDER BY 1,2 

--How many cases and deaths in total?
SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int))
	as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 
	as DeathPercentage
FROM PortfolioProject..covid_deaths
--WHERE location = 'United Kingdom'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

 -- 
 SELECT * 
 FROM PortfolioProject..covid_vacinations

 --looking at total population vs vacinations + rolling count 
 -- we need to partition by location so it keeps counts within countries

 SELECT dea.continent, dea.location, dea.date, dea.population
 , vac.new_vaccinations, SUM(cast(new_vaccinations as bigint)) 
 OVER (Partition By dea.location ORDER BY dea.location, dea.date) 
 as rolling_people_vaccinated,
 --(rolling_people_vaccinated/population)*100
 FROM PortfolioProject..covid_deaths dea
 JOIN PortfolioProject..covid_vacinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--using CTE to do (rolling_people_vaccinated/population)*100
WITH PopvsVac (continent, location, date, population, new_vaccinataions, rolling_people_vaccinated)
AS
(
 SELECT dea.continent, dea.location, dea.date, dea.population
 , vac.new_vaccinations, SUM(cast(new_vaccinations as bigint)) 
 OVER (Partition By dea.location ORDER BY dea.location, dea.date) 
 as rolling_people_vaccinated
 --,(rolling_people_vaccinated/population)*100
 FROM PortfolioProject..covid_deaths dea
 JOIN PortfolioProject..covid_vacinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (rolling_people_vaccinated/Population)*100 as rollingnumber
FROM PopvsVac

--using temp table to do (rolling_people_vaccinated/population)*100
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population
 , vac.new_vaccinations, SUM(cast(new_vaccinations as bigint)) 
 OVER (Partition By dea.location ORDER BY dea.location, dea.date) 
 as rolling_people_vaccinated
 --,(rolling_people_vaccinated/population)*100
 FROM PortfolioProject..covid_deaths dea
 JOIN PortfolioProject..covid_vacinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (rolling_people_vaccinated/population)*100
FROM #PercentPopulationVaccinated

--creating view to store data for late visualisations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population
 , vac.new_vaccinations, SUM(cast(new_vaccinations as bigint)) 
 OVER (Partition By dea.location ORDER BY dea.location, dea.date) 
 as rolling_people_vaccinated
 --,(rolling_people_vaccinated/population)*100
 FROM PortfolioProject..covid_deaths dea
 JOIN PortfolioProject..covid_vacinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated