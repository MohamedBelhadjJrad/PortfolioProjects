Select *
From covid19..CovidDeaths
Where continent is not null 
order by 3,4
go
-- Select Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population
From covid19..CovidDeaths
Where continent is not null 
order by 1,2
go
-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases,total_deaths, (cast(total_deaths as float)/total_cases)*100 as DeathPercentage
From covid19..CovidDeaths
Where location like '%tunisia%'
and continent is not null 
order by 1,2

go
-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases,  (cast(total_cases as float)/Population)*100 as PercentPopulationInfected
From covid19..CovidDeaths
Where location like '%tunisia%'
order by 1,2

go
-- Countries with Highest Infection Rate compared to Population
select location,population, max(total_cases) as HighestInfectionCount, max((cast(total_cases as float)/population)*100) as PercentPopulationInfected
from covid19..CovidDeaths
group by location,population
order by PercentPopulationInfected desc;

go
-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From covid19..CovidDeaths
--Where location like '%tuni%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc
go
-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From covid19..CovidDeaths
--Where location like '%tuni%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

go
-- GLOBAL NUMBERS
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as float))/SUM(New_Cases)*100 as DeathPercentage
From covid19..CovidDeaths
where continent is not null 
order by 1,2

go
-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid19..CovidDeaths dea
Join covid19..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3
go



-- Using CTE to perform Calculation on Partition By in previous query
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid19..CovidDeaths dea
Join covid19..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (cast(RollingPeopleVaccinated as float)/Population)*100
From PopvsVac
go


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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid19..CovidDeaths dea
Join covid19..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated
go



CREATE VIEW PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From covid19..CovidDeaths dea
Join covid19..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
go

-- This query calculates the hospitalization and death percentages for each location,
-- excluding entries where the continent is null.
-- It aggregates data from the covid19..CovidDeaths table,
-- sums the total cases, ICU patients, hospitalized patients, and total deaths,
-- and then calculates the percentages based on these sums.
-- The results are ordered by hospitalization percentage in descending order.
with NEW (location,tot_cases, tot_icu, tot_hosp, tot_death)
as (
select location,SUM(cast(total_cases as BIGINT)) as tot_cases, SUM(icu_patients) as tot_icu,SUM(hosp_patients) as tot_hosp, 
SUM(cast(total_deaths as BIGINT)) as tot_death
from covid19..CovidDeaths
Where continent is not null 
group by location
)
select *,((tot_icu + tot_hosp)/ cast(tot_cases as float))*100 as hosp_percentage,
(cast(tot_death as float) / tot_cases)*100 as death_percentage 
from NEW
order by hosp_percentage desc;
