
-- Comment �volue le pourcentage de morts par rapport au nombre de cas en France ? 

-- On constate une forte hausse de la mortalit� du virus jusqu'� la mi-mai 2020 (plus de 15%) puis une diminution constante (moins de 2% en avril 2021)
Select location, date, total_cases, new_deaths, total_deaths, ROUND((total_deaths/total_cases)*100,3) as Death_Percentage
From Covid_DB..CovidDeaths$
Where location like '%France%'
Order by 1,2 




-- Comment �volue la proportion de cas dans la population fran�aise ?

-- En tout, 8,33% de la population fran�aise a �t� contamin�e par le Covid entre mars 2020 et avril 2021.
-- La barre des 1% est franchie en juillet 2020. Celle des 2%, en octobre, et 3% en novembre. 
Select location, date, total_cases, population, new_deaths, total_deaths, ROUND((total_cases/population)*100,3) as Contamination_Percentage
From Covid_DB..CovidDeaths$
Where location like '%France%'
Order by 1,2 



-- Quel pays a subi le plus fort taux de contamination ?

-- Ce pays est Andorre.
Select location as Country, population as Population, MAX(total_cases) as Max_Cases, MAX(ROUND((total_cases/population)*100,3)) as Contamination_Percentage
From Covid_DB..CovidDeaths$
Group by Location, population
Order by 4 DESC



-- M�me question, avec les pays les plus peupl�s (+10M habitants) ?

-- Parmi les pays les plus peupl�s, la R�publique Tch�que a subi la plus forte contamination.
-- Toujours parmi ces pays, la France a �t� l'un des pays les plus touch�s. 
Select location as Country, population as Population, MAX(total_cases) as Max_Cases, MAX(ROUND((total_cases/population)*100,3)) as Contamination_Percentage
From Covid_DB..CovidDeaths$
WHERE Population > 10000000
Group by Location, population
Order by 4 DESC


-- Quel pays a subi le plus fort taux de mortalit� due au Covid ?

-- Ce pays est le Vanuatu... qui n'a � d�plorer qu'un mort sur quatre cas, soit 25% de taux de mortalit�..
Select location as Country, MAX(total_cases) as Number_of_Cases, (MAX(total_deaths)/MAX(total_cases)*100) as Mortality_rate
From Covid_DB..CovidDeaths$
Group by Location, population
Order by 3 DESC

-- Parmi les pays d�nombrant plus de 10.000 cas de Covid, c'est l'Egypte qui d�plore le plus haut taux de mortalit�.
Select location as Country, MAX(total_cases) as Number_of_Cases, (MAX(total_deaths)/MAX(total_cases)*100) as Mortality_rate
From Covid_DB..CovidDeaths$
Group by Location, population
Having MAX(total_cases) > 10000
Order by 3 DESC


-- Combien de morts chaque pays a-t-il eu � d�plorer du Covid ? (ne pas repr�senter les continents)

Select location as Country, population as Population, MAX(cast(total_deaths as Int)) as Death_toll
From Covid_DB..CovidDeaths$
Where continent is not null
Group by Location, population
Order by 3 DESC



-- Combien de morts chaque continent a-t-il eu � d�plorer ? 
Select location as Country, population as Population, MAX(cast(Total_deaths as Int)) as Death_toll, ROUND(MAX(cast(total_deaths as Int))/population*100,4) as Death_Percentage
From Covid_DB..CovidDeaths$
Where continent is null
Group by Location, population
Order by 3 DESC

-- Combien de morts chaque continent a-t-il eu � d�plorer ? 
-- Ces deux m�thodes ne renvoient pas les m�mes chiffres. Apr�s v�rification, la premi�re m�thode semble la plus fiable.
Select continent, MAX(cast(Total_deaths as Int)) as Death_toll
From Covid_DB..CovidDeaths$
Where continent is not null
Group by continent
Order by 2 DESC


-- Comment ont �volu� les nombres de cas et de morts du Covid au niveau mondial ?
Select date, SUM(cast(new_cases as INT)) as New_cases, SUM(cast(Total_cases as INT)) as Total_cases, SUM(cast(new_deaths as INT)) as New_deaths, SUM(cast(Total_deaths as INT)) as Death_toll
From Covid_DB..CovidDeaths$
Where (continent is not null) AND (Total_cases is not null) 
Group by date
Order by 1


-- Joindre les deux tables, afin d'analyser les rapports entre vaccination et morts du Covid. 
-- Permet de calculer par nous-m�mes la colonne "total_vaccinations".
-- La requ�te va additionner les valeurs de new_vaccinations, pour chaque morts.location.
Select  morts.continent, morts.location, morts.date, morts.population, vacci.new_vaccinations
, SUM(CONVERT(bigint, vacci.new_vaccinations)) Over (Partition by morts.Location Order by morts.location, morts.date) as Total_vaccinations 
From Covid_DB..CovidDeaths$ morts
Join Covid_DB..CovidVaccinations$ vacci On vacci.location = morts.location and vacci.date = morts.date	
Where morts.continent is not null
Group by morts.date, morts.continent, morts.location, morts.population, vacci.new_vaccinations Having COUNT(*) >1
Order By 2,3


-- En utilisant une CTE, calculer l'�volution du taux de vaccination dans la population
-- En France, on retrouve la date de la premi�re injection du vaccin anti-Covid, le 27 d�cembre 2020. 

WITH Ratio_vaccin (Continent, Location, Date, Population, New_vaccinations, Total_vaccinations)
as
(
Select  morts.continent, morts.location, morts.date, morts.population, vacci.new_vaccinations
, SUM(CONVERT(bigint, vacci.new_vaccinations)) Over (Partition by morts.Location Order by morts.location, morts.date) as Total_vaccinations 
From Covid_DB..CovidDeaths$ morts
Join Covid_DB..CovidVaccinations$ vacci On vacci.location = morts.location and vacci.date = morts.date	
Where morts.continent is not null 
--and morts.location like '%France%'
Group by morts.date, morts.continent, morts.location, morts.population, vacci.new_vaccinations Having COUNT(*) >1
--Order By 2,3
)
Select *, ROUND((Total_vaccinations/Population)*100,4) as Ratio_vaccination_population
From Ratio_vaccin



--Cr�ation d'une vue de l'�volution du nombre de vaccinations pour pr�parer la datavisualisation

Create view PourcentageVaccin as
Select  morts.continent, morts.location, morts.date, morts.population, vacci.new_vaccinations
, SUM(CONVERT(bigint, vacci.new_vaccinations)) Over (Partition by morts.Location Order by morts.location, morts.date) as Total_vaccinations 
From Covid_DB..CovidDeaths$ morts
Join Covid_DB..CovidVaccinations$ vacci On vacci.location = morts.location and vacci.date = morts.date	
Where morts.continent is not null
Group by morts.date, morts.continent, morts.location, morts.population, vacci.new_vaccinations Having COUNT(*) >1
--Order By 2,3

Select * From PourcentageVaccin