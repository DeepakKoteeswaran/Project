/*
Covid 19 Data Exploration on March 08, 2023

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

--1. order by location and date
Select *
FROM [Project Portfolio].[dbo].[deaths$]
Where continent is not null 
order by 3,4



--2. Select Data to start with

Select Location, date, total_cases, new_cases, total_deaths, population
From [Project Portfolio].[dbo].[deaths$]
Where continent is not null 
order by 1,2


--3. Total Cases vs Total Deaths (Shows likelihood of dying if we contract covid in a country)

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [Project Portfolio].[dbo].[deaths$]
Where location like '%states%'
and continent is not null 
order by 1,2


--4. Total Cases vs Population (Shows what percentage of population infected with Covid)

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From [Project Portfolio].[dbo].[deaths$]
order by 1,2


--5. Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From [Project Portfolio].[dbo].[deaths$]
Group by Location, Population
order by PercentPopulationInfected desc


--6. Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Project Portfolio].[dbo].[deaths$]
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



--7. Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Project Portfolio].[dbo].[deaths$]
Where continent is not null 
Group by continent
order by TotalDeathCount desc



--8. Global numbers

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From [Project Portfolio].[dbo].[deaths$]
where continent is not null 
order by 1,2



-- 9. Shows rolling count on people vaccinated in a country

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Project Portfolio].[dbo].[deaths$] dea
Join [Project Portfolio].[dbo].[Sheet1$] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


--10. Shows Percentage of Population that has recieved at least one Covid Vaccine Using CTE 

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

From [Project Portfolio].[dbo].[deaths$] dea
Join [Project Portfolio].[dbo].[Sheet1$] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



--11. Using Temp Table to perform Calculation on Partition By in previous query

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
From [Project Portfolio].[dbo].[deaths$] dea
Join [Project Portfolio].[dbo].[Sheet1$] vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




--12. Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From [Project Portfolio].[dbo].[deaths$] dea
Join [Project Portfolio].[dbo].[Sheet1$] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 


