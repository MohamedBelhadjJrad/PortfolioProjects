/*

Queries used for Tableau Project

*/

-- 0
-- Global Numbers
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as float))/SUM(New_Cases)*100 as DeathPercentage
From covid19..CovidDeaths
where continent is not null 
order by 1,2
go



-- 1
with NEW (continent,tot_cases, tot_icu, tot_hosp)
as (
select continent,SUM(cast(total_cases as BIGINT)) as tot_cases, SUM(icu_patients) as tot_icu,SUM(hosp_patients) as tot_hosp
from covid19..CovidDeaths
--Where continent is  null 
group by continent
)
select top 3 *,((tot_icu + tot_hosp)/ cast(tot_cases as float))*100 as hosp_percentage
from NEW
order by hosp_percentage desc;
go



-- 2
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From covid19..CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc;
go


-- 3
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((cast(total_cases as float)/population))*100 as PercentPopulationInfected
From covid19..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc;
go


-- 4
Select Location, date, population, total_cases, total_deaths
From covid19..CovidDeaths
where continent is not null 
order by 1,2;
go



-- 5
go
With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From covid19..CovidDeaths dea
Join covid19..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (cast(RollingPeopleVaccinated as float)/Population)*100 as PercentPeopleVaccinated
From PopvsVac;
go


--6
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((cast(total_cases as float)/population))*100 as PercentPopulationInfected
From covid19..CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc;
