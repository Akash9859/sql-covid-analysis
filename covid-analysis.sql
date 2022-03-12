Select *
From dbo.CovidDeaths

Select population
From dbo.CovidVaccinations

/*Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select *
From Covid19..CovidDeaths
Where continent is not null 
order by 3,4


--ALTER TABLE Covid19..CovidDeaths
--ADD population BIGINT NULL;

--insert into Covid19..CovidDeaths (population)
--select population 
--from Covid19..CovidVaccinations

--UPDATE Covid19..CovidDeaths
--SET Covid19..CovidDeaths..population = Covid19..CovidVaccinations..population
--FROM Covid19..CovidDeaths
--     JOIN Covid19..CovidVaccinations ON Covid19..CovidDeaths..location = Covid19..CovidVaccinations..location;
---- Select Data that we are going to be starting with

--alter table Covid19..CovidDeaths
--drop column population

Select Location, date, total_cases, new_cases, total_deaths
From Covid19..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Covid19..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From Covid19..CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select dea.Location, vac.Population, MAX(dea.total_cases) as HighestInfectionCount,  Max((dea.total_cases/vac.population))*100 as PercentPopulationInfected
From Covid19..CovidDeaths dea
--Where location like '%states%'
Join Covid19..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Group by dea.Location, vac.Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From Covid19..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

Select Location, SUM(cast(total_deaths as int)) as TotalDeathCount
From Covid19..CovidDeaths
Where continent is not null
	and location not in ('World', 'European Union', 'International') 
Group by Location
order by TotalDeathCount desc


-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Covid19..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Covid19..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2


Select CovidDeaths.location 
from Covid19..CovidDeaths
where CovidDeaths.location is not null
Order by CovidDeaths.location

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

--ALTER TABLE Covid19..CovidDeaths  ALTER COLUMN location  nvarchar(150)

Select dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100

From Covid19..CovidDeaths dea
Join Covid19..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

select vac.population, vac.new_vaccinations
from Covid19..CovidVaccinations vac
order by 2

Select dea.continent, dea.location, dea.date
From Covid19..CovidDeaths dea
where dea.continent is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query
--Pending
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid19..CovidDeaths dea
Join Covid19..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as Percent_Population_Vaccinated
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 