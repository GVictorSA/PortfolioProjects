
Select *
From [Portfolio Project ]..CovidDeaths
where continent is not null
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From [Portfolio Project ]..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths


Select Location, date, total_cases,total_deaths, ((try_convert(float, total_deaths)/(try_convert(float, total_cases))))*100 as DeathPercentage
From [Portfolio Project ]..CovidDeaths
where location like '%states%' and continent is not null 
order by 1,2

-- Total Cases vs Population

Select Location, date, Population, total_cases,  ((try_convert(float, total_cases)/(try_convert(float, population))))*100 as PercentPopulationInfected
From [Portfolio Project ]..CovidDeaths
Where location like '%states%'
order by 1,2

Select Location, Population, max(total_cases) as HighestInfectionCount,  Max((try_convert(float, total_cases)/(try_convert(float, population))))*100 as PercentPopulationInfected
From [Portfolio Project ]..CovidDeaths
--Where location like '%states%'
group by location, population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population

Select Location, MAX(cast(try_convert(float, Total_deaths) as int)) as TotalDeathCount
From [Portfolio Project ]..CovidDeaths
--Where location like '%states%'
Where continent is not null 
--Remove continents like World, Africa, etc
Group by Location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

Select continent, MAX(cast(try_convert(float, Total_deaths) as int)) as TotalDeathCount
From [Portfolio Project ]..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

--The correct way to show the continents with the highest death count per population!

--Select location, MAX(cast(try_convert(float, Total_deaths) as int)) as TotalDeathCount
--From [Portfolio Project ]..CovidDeaths
--Where location like '%states%'
--Where continent is null 
--Group by location
--order by TotalDeathCount desc

-- GLOBAL NUMBERS

Select date, SUM(try_convert(float, new_cases)) as total_cases, SUM(cast(try_convert(float, new_deaths) as int)) as total_deaths, SUM(cast(try_convert(float, new_deaths) as int))/SUM(try_convert(float, New_Cases))*100 as GlobalDeathPercentage
From [Portfolio Project ]..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
group by date
order by 1,2

Select  SUM(try_convert(float, new_cases)) as total_cases, SUM(cast(try_convert(float, new_deaths) as int)) as total_deaths, SUM(cast(try_convert(float, new_deaths) as int))/SUM(try_convert(float, New_Cases))*100 as GlobalDeathPercentage
From [Portfolio Project ]..CovidDeaths
--Where location like '%states%'
where continent is not null 
order by 1,2

-- Total Population vs Vaccinations
--Partition runs and stops per dea.location

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(try_CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project ]..CovidDeaths as dea
Join [Portfolio Project ]..CovidVaccinations as vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

--Use CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(try_CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project ]..CovidDeaths dea
Join [Portfolio Project ]..CovidVaccinations vac
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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project ]..CovidDeaths dea
Join [Portfolio Project ]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project ]..CovidDeaths dea
Join [Portfolio Project ]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select *
from PercentPopulationVaccinated