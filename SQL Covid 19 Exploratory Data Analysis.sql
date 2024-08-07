Select Location, date, total_cases,total_deaths,(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS Deathpercentage,population 
From portfolioproject..CovidDeaths
order by 1,2


--looking at tota cases vs total deaths
-- shows the liklihood of dying if you contract covid in india

Select Location, date, total_cases,total_deaths,(CONVERT(float,total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 AS Deathpercentage,population 
From portfolioproject..CovidDeaths
Where Location like '%india%'
order by 1,2


--looking at the total cases versus population
--shows what percentage of the population got covid

Select Location, date, total_cases,population,(NULLIF(CONVERT(float,total_cases),0)/population)*100 AS PercentPopulationInfected
From portfolioproject..CovidDeaths
Where Location like '%india%'
order by 1,2


--looking at countries with highest infection rate wrt population

Select Location,population,MAX(total_cases) as HighestInfectionCount,Max((NULLIF(CONVERT(float,total_cases),0))/population)*100 
 AS PercentPopulationInfected 
From portfolioproject..CovidDeaths
Group By Location,population
order by PercentPopulationInfected desc


--countries with the highest death count per population

SELECT 
    Location,
    MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM 
    portfolioproject..CovidDeaths
WHERE
     continent is not null
GROUP BY 
    Location, population
ORDER BY 
   TotalDeathCount DESC;


--breaking it down by continent

SELECT 
    location,
    MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM 
    portfolioproject..CovidDeaths
WHERE
     continent is null
GROUP BY 
      location
ORDER BY 
   TotalDeathCount DESC;


--Showing the continent with the highest death count per population

SELECT 
    continent,
    MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM 
    portfolioproject..CovidDeaths
WHERE
     continent is not null
GROUP BY 
       continent
ORDER BY 
   TotalDeathCount DESC


--Global Numbers

SELECT 
    --date,
    SUM(COALESCE(new_cases, 0)) AS TotalNewCases, 
    SUM(CAST(COALESCE(new_deaths, 0) AS float)) AS TotalNewDeaths,
    CASE 
        WHEN SUM(COALESCE(new_cases, 0)) = 0 THEN 0 
        ELSE SUM(CAST(COALESCE(new_deaths, 0) AS float)) / SUM(COALESCE(new_cases, 0)) * 100 
    END AS DeathPercentage
FROM 
    portfolioproject..CovidDeaths
WHERE 
    continent IS NOT NULL
--GROUP BY 
  --  date
ORDER BY 
    1,2;


-- looking at total population vs vaccinations

Select 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint,vac.new_vaccinations) )
        OVER (Partition by dea.location order by dea.location,dea.date) AS RollingPeopleVaccinated
from 
    portfolioproject..CovidDeaths dea
join 
    portfolioproject..CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date
where 
    dea.continent is not null
order by 
    dea.location, dea.date;

Select 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations
    
from 
    portfolioproject..CovidDeaths dea
join 
    portfolioproject..CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date
where 
    dea.continent is not null
order by 2,3


--USE CTE

with PopvsVac (Continent,Location,Date,Population,New_Vaccinations,RollingPeopleVaccinated)
as 
(
Select 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(float,vac.new_vaccinations) )
        OVER (Partition by dea.location order by dea.location,dea.date) AS RollingPeopleVaccinated
from 
    portfolioproject..CovidDeaths dea
join 
    portfolioproject..CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date

where dea.continent is not null
--order by 2,3
	)
	Select  *,(RollingPeopleVaccinated/population)*100
	From PopvsVac

--TEMP TABLE

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
location nvarchar(255),
Date datetime,
population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(float,vac.new_vaccinations) )
        OVER (Partition by dea.location order by dea.location,dea.date) AS RollingPeopleVaccinated
from 
    portfolioproject..CovidDeaths dea
join 
    portfolioproject..CovidVaccinations vac
    on dea.location = vac.location
    and dea.date = vac.date

--where dea.continent is not null
--order by 2,3

Select  *,(RollingPeopleVaccinated/population)*100
	From #PercentPopulationVaccinated


--Creating view to store data for visualisation

Use portfolioproject;
Create VIEW dbo.PercentPopulationVaccinated AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(float,vac.new_vaccinations))
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    portfolioproject..CovidDeaths dea
JOIN 
    portfolioproject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL

Select *
from dbo.PercentPopulationVaccinated

-- Analysing COVID Percentages by Total Cases vs Population for different ranges of  Human Development Index 
-- Range :  Very High 
Select 
dea.location, max(total_cases) as highestcasecount, vac.gdp_per_capita, vac.human_development_index, 
max(total_cases/dea.population)*100 as PercentageofCasesByPopulation
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null and vac.human_development_index > 0.80
group by dea.location, vac.gdp_per_capita, vac.human_development_index
order by PercentageofCasesByPopulation desc

--Range : High  
Select 
dea.location, max(total_cases) as highestcasecount, vac.gdp_per_capita, vac.human_development_index, 
max(total_cases/dea.population)*100 as PercentageofCasesByPopulation
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null and vac.human_development_index  between 0.70 and 0.79
group by dea.location, vac.gdp_per_capita, vac.human_development_index
order by PercentageofCasesByPopulation desc

--Range : Medium 
Select 
dea.location, max(total_cases) as highestcasecount, vac.gdp_per_capita, vac.human_development_index, 
max(total_cases/dea.population)*100 as PercentageofCasesByPopulation
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null and vac.human_development_index  between 0.55 and 0.70
group by dea.location, vac.gdp_per_capita, vac.human_development_index
order by PercentageofCasesByPopulation desc

--Range : Low 
Select 
dea.location, max(total_cases) as highestcasecount, vac.gdp_per_capita, vac.human_development_index, 
max(total_cases/dea.population)*100 as PercentageofCasesByPopulation
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent  is not null and vac.human_development_index  < 0.55
group by dea.location, vac.gdp_per_capita, vac.human_development_index
order by PercentageofCasesByPopulation desc

--Countries with Most Consistent Case Reporting

WITH DailyVariance AS (
    SELECT 
        location,
        STDEV(new_cases) OVER (PARTITION BY location) AS StdDevNewCases
    FROM 
        portfolioproject..CovidDeaths
    WHERE 
        continent IS NOT NULL
)
SELECT 
    location,
    AVG(StdDevNewCases) AS AvgStdDevNewCases
FROM 
    DailyVariance
GROUP BY 
    location
ORDER BY 
    AvgStdDevNewCases Desc

--Mortality Rate by Age Group

--age>65

SELECT 
    dea.location, 
    vac.aged_65_older,
    SUM(CAST(dea.total_cases AS float)) AS TotalCases,
    SUM(CAST(dea.total_deaths AS float)) AS TotalDeaths,
    (SUM(CAST(dea.total_deaths AS float)) * 1.0 / SUM(CAST(dea.total_cases AS float))) * 100 AS MortalityRate
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
GROUP BY 
    dea.location, 
    vac.aged_65_older
ORDER BY 
    MortalityRate DESC;

--age>70
SELECT 
    dea.location, 
    vac.aged_70_older,
    SUM(CAST(dea.total_cases AS float)) AS TotalCases,
    SUM(CAST(dea.total_deaths AS float)) AS TotalDeaths,
    (SUM(CAST(dea.total_deaths AS float)) * 1.0 / SUM(CAST(dea.total_cases AS float))) * 100 AS MortalityRate
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
GROUP BY 
    dea.location, 
    vac.aged_70_older
ORDER BY 
    MortalityRate DESC;



--Mortality Rate by Handwashing Facilities
SELECT 
    vac.handwashing_facilities,dea.location,
    SUM(cast(dea.total_cases as float)) AS TotalCases,
    SUM(cast(dea.total_deaths as float)) AS TotalDeaths,
    (SUM(cast(dea.total_deaths as float)) * 1.0 / SUM(cast(dea.total_cases as float ))) * 100 as MortalityRate
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
GROUP BY 
    vac.handwashing_facilities,dea.location
ORDER BY 
    MortalityRate DESC 
	


