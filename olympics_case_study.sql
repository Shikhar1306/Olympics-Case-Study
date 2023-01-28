--1. How many olympics games have been held?

select count(distinct Games) total_olympic_games
from athlete_events;

--2. List down all Olympics games held so far.

select distinct Games, Year, Season, City
from athlete_events
order by Year;

--3. Mention the total no of nations who participated in each olympics game?

select Games, count(distinct NOC) total_countries
from athlete_events
group by Games
order by Games;

--4. Which year saw the highest and lowest no of countries participating in olympics?

with total_countries_cte as
(
	select Games, count(distinct NOC) total_countries
	from athlete_events
	group by Games
)
select distinct concat(first_value(Games) over (order by total_countries),' - ',first_value(total_countries) over (order by total_countries)) lowest_countries,
 concat(first_value(Games) over (order by total_countries desc),' - ',first_value(total_countries) over (order by total_countries desc)) highest_countries
from total_countries_cte;

--5. Which nation has participated in all of the olympic games?

with total_games as
(
	select count(distinct Games) total_olympic_games
	from athlete_events
),
all_countries_cte as
(
	select ae.Games, nr.region Country
	from athlete_events ae
	inner join noc_regions nr
	on ae.NOC = nr.NOC
	group by ae.Games, nr.region
),
count_countries_participation as
(
	select Country, count(1) total_participated_olympics
	from all_countries_cte
	group by Country
)
select * 
from count_countries_participation
where total_participated_olympics = (select total_olympic_games from total_games);

--6. Identify the sport which was played in all summer olympics.

select * from athlete_events;

with total_summer_olympics as
(
	select count(distinct Games) as total_summer_games
	from athlete_events
	where Season = 'Summer'
),
all_sports as
(
	select Games, Sport
	from athlete_events
	where Season = 'Summer'
	group by Games, Sport
),
count_all_sports as
(
	select Sport, count(Games) as times_played
	from all_sports
	group by Sport
)
select * from count_all_sports
where times_played = (select total_summer_games from total_summer_olympics);

--7. Which Sports were just played only once in the olympics?

with all_sports as
(
	select Games, Sport
	from athlete_events
	group by Games, Sport
),
sports_count as
(
	select Sport, count(Games) times_played
	from all_sports
	group by Sport
	having count(Games) = 1
)
select * from sports_count

--8. Fetch the total no of sports played in each olympic games.

select Games, count(distinct Sport) no_of_sports_played 
from athlete_events
group by Games
order by no_of_sports_played desc

--9. Fetch oldest athletes to win a gold medal

select Name, Sex, Age, Team, NOC, Games, City, Sport, Event, Medal
from athlete_events
where Medal = 'Gold' and Age = (select max(Age) 
								from athlete_events
								where Medal = 'Gold'
								);

--10. Find the Ratio of male and female athletes participated in all olympic games.

with count_by_sex as
(
	select sum(case when Sex = 'M' then 1.0 else 0 end) count_males,
	sum(case when Sex = 'F' then 1.0 else 0 end) count_females
	from athlete_events
)
select concat(1,' : ',cast(round(count_males/count_females,2) as decimal(18,2))) ratio
from count_by_sex;

--11. Fetch the top 5 athletes who have won the most gold medals.

with medal_count as
(
	select Name, Team, count(Medal) total_gold_medals
	from athlete_events
	where Medal = 'Gold'
	group by Name, Team
),
medal_count_rank as
(
	select *, dense_rank() over(order by total_gold_medals desc) rnk
	from medal_count
)
select Name, Team, total_gold_medals
from medal_count_rank
where rnk <= 5
order by rnk;

--12. Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).

with medal_count as
(
	select Name, Team, count(Medal) total_medals
	from athlete_events
	where Medal in ('Bronze', 'Silver', 'Gold')
	group by Name, Team
),
medal_count_rank as
(
	select *, dense_rank() over(order by total_medals desc) rnk
	from medal_count
)
select Name, Team, total_medals
from medal_count_rank
where rnk <= 5
order by rnk;

--13. Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.

with total_medals as
(
	select nr.region, count(ae.Medal) total_medals
	from athlete_events ae
	inner join noc_regions nr
	on ae.NOC = nr.NOC
	where Medal in ('Bronze', 'Silver', 'Gold')
	group by nr.region
),
total_medals_rank as
(
	select *, dense_rank() over(order by total_medals desc) rnk
	from total_medals
)
select *
from total_medals_rank
where rnk <= 5;

--14. List down total gold, silver and bronze medals won by each country.

select nr.region Country,
sum(case when Medal = 'Gold' then 1 else 0 end) gold,
sum(case when Medal = 'Silver' then 1 else 0 end) silver,
sum(case when Medal = 'Bronze' then 1 else 0 end) bronze
from athlete_events ae
inner join noc_regions nr
on ae.NOC = nr.NOC
group by nr.region
order by gold desc;

--15. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.

select ae.Games,nr.region Country,
sum(case when Medal = 'Gold' then 1 else 0 end) gold,
sum(case when Medal = 'Silver' then 1 else 0 end) silver,
sum(case when Medal = 'Bronze' then 1 else 0 end) bronze
from athlete_events ae
inner join noc_regions nr
on ae.NOC = nr.NOC
group by ae.Games, nr.region
order by ae.Games, nr.region;

