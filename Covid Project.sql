/* Creating table CovidVaccinations to import data */
-- CovidDeaths table was imported in the same way

Create table CovidVaccinations
(
Id int8 primary key,
iso_code char(3),
continent varchar(20),
location	varchar(20),
date varchar(20),
total_tests	int8,
new_tests	int8,
total_tests_per_thousand float,
new_tests_per_thousand	float,
new_tests_smoothed	float,
new_tests_smoothed_per_thousand	float,
positive_rate	float,
tests_per_case	float,
tests_units	varchar(50),
total_vaccinations int8,
people_vaccinated int8,
people_fully_vaccinated	int8,
total_boosters int8,
	new_vaccinations int8,	
	new_vaccinations_smoothed int8,
	total_vaccinations_per_hundred float,
	people_vaccinated_per_hundred	float,
	people_fully_vaccinated_per_hundred float,
	total_boosters_per_hundred	float,
	new_vaccinations_smoothed_per_million	float,
	new_people_vaccinated_smoothed	float,
	new_people_vaccinated_smoothed_per_hundred	float,
	stringency_index float,	
	population_density float,	
	median_age	float,
	aged_65_older float,	
	aged_70_older float,
	gdp_per_capita float,
	extreme_poverty	float,
	cardiovasc_death_rate	float,
	diabetes_prevalence	float,
	female_smokers	float,
	male_smokers	float,
	handwashing_facilities float,
	hospital_beds_per_thousand	float,
	life_expectancy	float,
	human_development_index	float,
	excess_mortality_cumulative_absolute float,
	excess_mortality_cumulative	float,
	excess_mortality float,	
	excess_mortality_cumulative_per_million float );
	
/* Let's look at the Deaths file */

SELECT * FROM CovidDeaths
ORDER BY Id;

-- Order by Id to match with Excel file

/* Select the columns I am interested in */

SELECT Id,location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
Order by 1

/* Total Cases vs Total Deaths Shows likelihood of death if contracted covid in my country */

SELECT Id,location, date, total_cases, total_deaths, ((cast(total_deaths as float))/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE location like 'India'
ORDER BY 1;

-- Create DeathPercentage column that calculates % of covid deaths
-- total_deaths is nvarchar(255). Need to cast as int.
-- Filter India location using the LIKE operator.

/* Total Cases vs Population Shows what percentage of the population contracted covid */

SELECT Id,location, date, population, total_cases,((cast(total_cases as float))/population)*100 as CovidPercentage
FROM CovidDeaths
ORDER BY 1;

/* Countries with Highest Death Count per Population  with WHERE is not null clause */

SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount 
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc;

/* Let's look at Vaccinations file */

SELECT * FROM CovidVaccinations

/* JOIN Deaths and Vaccinations tables */

-- joining based on location and date

SELECT deaths.Id, deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
FROM coviddeaths as deaths
JOIN covidvaccinations as vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
ORDER BY 1, 2, 3

/* Total Population vs Vaccinations */

-- Must cast new_vaccinations as BIGINT because it exceeds max int.

SELECT deaths.Id, deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations, SUM(cast(vaccinations.new_vaccinations as bigint)) 
OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as RollingPeopleVaccinated

-- , (RollingPeopleVaccinated/population)*100

/* You can't call a column you just made, so you'll need to make a CTE or temp table Partition by location : the aggregate count will stop and start over at each location so it doesn't total everything */

FROM coviddeaths as deaths
JOIN covidvaccinations as vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
ORDER BY 1, 3

/* Total Population vs Vaccinations USING CTE */

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)

-- You need the same number of columns called here as in the SELECT columns

as
(
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations , SUM(cast(vaccinations.new_vaccinations as bigint)) 
OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as RollingPeopleVaccinated

FROM coviddeaths as deaths

JOIN covidvaccinations as vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
)

SELECT location,new_vaccinations,date,(RollingPeopleVaccinated/population)*100 as Vacinated_Population
FROM PopvsVac 
Order by 1,2,3;

/* Total Population vs Vaccinations USING Temp Table */

Create Table PercentPopulationVaccinated
(continent varchar(255),
location varchar(255),
date varchar(255),
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric);

Insert into PercentPopulationVaccinated
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations , SUM(cast(vaccinations.new_vaccinations as bigint)) 
OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as RollingPeopleVaccinated
FROM coviddeaths as deaths

JOIN covidvaccinations as vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date;

SELECT location,new_vaccinations,date,(RollingPeopleVaccinated/population)*100 as Vacinated_Population
FROM PercentPopulationVaccinated
Order by 1,2,3 

/* Creating View to store data for later visualizations */

CREATE VIEW PercentPopulationVaccinated as
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations , SUM(cast(vaccinations.new_vaccinations as bigint)) 
OVER (Partition by deaths.location ORDER BY deaths.location, deaths.date) as RollingPeopleVaccinated

-- , (RollingPeopleVaccinated/population)*100

FROM coviddeaths as deaths
JOIN covidvaccinations as vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null

/* Let's see the saved VIEW. */

`SELECT * FROM PercentPopulationVaccinated`