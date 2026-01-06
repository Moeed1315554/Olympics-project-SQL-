use game;     
select *
from city;
select *
from competitor_event;
select *
from event;
select *
from games; 
select *
from games_city;
select *
from games_competitor;
select *
from medal;
select *
from noc_region;
select *
from person;
select *
from person_region;
select *
from event;
select *
from sport;






## Are there any trends or patterns in the frequency of hosting Olympic Games?
         
      
       with moeed as(              
          with frequences as (           
                     select id,
                            games_year,lag(games_year) over (partition by season order by games_year asc) as lg,
                            season
						from games   
                        order by games_year)
			select 
               season,
               games_year,
               (games_year-lg) as frequencyOFpreviousGame
			from frequences
            )
    select season,
    frequencyOFpreviousGame,
    count(*) as timesOFgap
    from moeed
    where frequencyOFpreviousGame is not null
    group by season,
    frequencyOFpreviousGame
    order by season,timesOFgap desc;
    
    #
    




##How has the duration of Olympic Games changed over time?
    with moeed as(
           with duration as(
                select 
                    season,
                    city_name,
                    games_year,
                    lag(games_year) over (partition by season order by games_year asc) as previous_year
				 from games as g
                 join games_city as gc on g.id=gc.games_id
                 join city as c on gc.city_id=c.id
                  )
     select 
         season,
         city_name,
         (games_year-previous_year) as gap_year
         from 
         duration
         )
  select 
     season,
     city_name,
     gap_year,
     count(*) as duration_gap_times
	from moeed
    where gap_year is not null
    group by 
      season,gap_year,city_name
    order by 
        duration_gap_times desc, season;
	
      






##Are there any notable events or occurrences associated with specific Olympic Games?


with athelet_count as(
					select 
                        g.id as games_id,
                        g.games_year,
                        g.season,
                        count( distinct gc.person_id) as total_athelets
					  from games as g
                      join games_competitor as gc on g.id=gc.games_id
                      group by 
                           g.id,
                           g.games_year,
                           g.season
                        ),
                        
 sport_introduction as  (
                     select
                         g.id as games_id,
                         count(distinct s.id) as sport_count
					from games as g
                        join games_competitor as gc on g.id=gc.games_id
                        join competitor_event as ce on gc.id=ce.competitor_id
                        join event as e on ce.event_id=e.id
                        join sport as s on e.sport_id=s.id
					 group by g.id
                       ),
 medal_domenance as(
			select
                games_id,
               max(medal_count) as max_medal_country
			from
				(select
                       g.id as games_id,
                       nr.region_name,
                       count(*) as medal_count
					from games as g
                      join games_competitor as gc on g.id=gc.games_id
                      join competitor_event as ce on gc.id=ce.competitor_id
                      join medal as m on ce.medal_id=m.id
                      join person_region as pr on gc.person_id=pr.person_id
                      join noc_region as nr on pr.region_id=nr.id
					where m.medal_name<>'NA'
					group by 
                        games_id,
                        nr.region_name) as k
				group by
					games_id
				)
                       
select 
        ac.games_year,
        ac.season,
        ac.total_athelets,
        si.sport_count,
        md.max_medal_country,
          case 
             when
               ac.total_athelets<1000 then 'Low Participation (boycott/disruption)'
			when 
               ac.total_athelets>1000 then 'High Participation (High Expansion)'
			when 
               md.max_medal_country>50 then 'medal Domenance'
			else 'Stander Olympic Games'
		  end AS notable_region
 from 
     athelet_count as ac
	join sport_introduction as si using(games_id)
    join  medal_domenance as md using(games_id)
 order by ac.games_year;
     
                   
                         














##Are there any emerging sports that have been recently added to the Olympics?
       
			select 
                   g.season,
                   s.sport_name,
                   min(g.games_year) as recent_year
				from games as g
                  join games_competitor  as gc on
                                              g.id=gc.games_id
                  join competitor_event as ce on 
											  gc.id=ce.competitor_id
                  join event as e on
								  ce.event_id=e.id
                  join sport as s on 
                                  e.sport_id=s.id
                                  
                  group by 
                      g.season,
                   s.sport_name
                                  
                having min(g.games_year) >'1994'
                order by 
                   recent_year;
                 

       
         
                   




## How has the popularity of certain sports changed over the years?

 with moeed as(   
    with count_popularity as(
					select 
                         s.sport_name,
                         g.games_name,
                         g.season,
                         g.games_year,
						count(gc.person_id) as player_participate
                        
					   from games as g
                        join games_competitor as gc on
                                         g.id=gc.games_id
                        join competitor_event as ce on
                                         gc.id=ce.competitor_id
                        join event as e on
										 ce.event_id=e.id
						join sport as s on 
                                         e.sport_id=s.id
                       group by 
                           s.sport_name,
                           g.games_name,
                         g.season,
                         g.games_year
					   order by games_year
                         )
   select sport_name,season,games_year,player_participate ,
      lag(player_participate)over (partition by sport_name,season order by games_year) as previous_year_participate
	from count_popularity
    )
select *, round((player_participate-previous_year_participate)*100/player_participate,2) as percent
 from moeed
 where previous_year_participate is not null;
 



##Are there any sports that are specific to a particular region or culture?

        with moeed as(
               select s.id,
                   s.sport_name,
                   count(distinct nr.region_name) as participate_regions
				from sport as s
                  join event as e on
                        s.id=e.sport_id
				  join competitor_event as ce on
                        e.id=ce.event_id
				  join games_competitor as gc on 
                        ce.competitor_id=gc.id
				  join person_region as pr on
                        gc.person_id=pr.person_id
                join noc_region as nr on
                        pr.region_id=nr.id
				group by s.id,
                     s.sport_name
				),
 regions as(
       select s.id,
       nr.region_name
	
       from sport as s
                  join event as e on
                        s.id=e.sport_id
				  join competitor_event as ce on
                        e.id=ce.event_id
				  join games_competitor as gc on 
                        ce.competitor_id=gc.id
				  join person_region as pr on
                        gc.person_id=pr.person_id
                join noc_region as nr on
                        pr.region_id=nr.id
                  )
 select distinct
      m.*,r.region_name
	from moeed as m
    join regions as r using(id)
  where participate_regions<=2
  order by sport_name,participate_regions;



##Are there any sports that have a higher number of events for one gender compared to others?
with moeed as(
  select 
     s.sport_name,
     sum(
			case 
               when 
                 e.event_name like '%Men%' then 1 else 0 end) as  male_event,
     sum(
			case 
               when 
                 e.event_name like '%Women%' then 1 else 0 end) as femail_event
   from sport as s
    join event as e on
               s.id=e.sport_id
   group by s.sport_name            
     )
select *
  from moeed
where 
   male_event<>femail_event
order by sport_name;
               
               

##Are there any new events that have been introduced in recent editions of the Olympics?


		
				select
                      min(g.games_year) as first_year_introduce,
                      e.event_name
					from games as g
                     join games_competitor as gc on 
                                        g.id=gc.games_id
					 join competitor_event as ce on
                                        gc.id=ce.competitor_id
                     join event as e on
                                        ce.event_id=e.id
                     group by e.event_name
                     having min(g.games_year)>'2000' 
                     order by min(g.games_year);
                    




## Are there any events that have been discontinued or removed from the Olympics?



				select
                      max(g.games_year) as last_year_appeared,
                      e.event_name
					from games as g
                     join games_competitor as gc on 
                                        g.id=gc.games_id
					 join competitor_event as ce on
                                        gc.id=ce.competitor_id
                     join event as e on
                                        ce.event_id=e.id
                     group by e.event_name
                     having max(g.games_year)<'2016' 
                     order by max(g.games_year);



## Are there any notable trends in the height and weight of participants over time?
   with yearly_trands as(
         with yearly_avg as(
                  select distinct
                        g.games_year,
                        p.gender,
                        avg(p.height) over (partition by games_year,gender) as yearly_avg_height,
                        avg(p.weight) over (partition by games_year,gender) as yearly_avg_weight
                     from games as g
                       join games_competitor as gc on
												g.id=gc.games_id
                       join person as p on
									  gc.person_id=p.id
					 where p.height!=0 and p.weight!=0
                     )
            
            select *,
                 lag(yearly_avg_height) over () as previous_year_avg_height,
                 lag(yearly_avg_weight) over () as previous_year_avg_weight
			 from yearly_avg
                 )
	select 
       games_year,
       gender,
       yearly_avg_height,
       round((yearly_avg_height-previous_year_avg_height)*100.0/yearly_avg_height,2) as trands_height,
       yearly_avg_weight,
       round((yearly_avg_weight-previous_year_avg_weight)*100.0/yearly_avg_weight,2) as trands_weight
	 from 
        yearly_trands
     where               
        previous_year_avg_height is not null 
          and  
		 previous_year_avg_weight is not null;
  
                     
                     
                     
                     
                     
                     

## Are there any dominant countries or regions in specific sports or events?


with sport_yearly_domenance as(
				select 
                        g.games_year,
                        g.season,
                        s.sport_name,
                        nr.region_name as country_dominance,
                        count(*) as medal_count
					from games as g
						join games_competitor as gc
                                 on g.id=gc.games_id
						join competitor_event as ce
                                 on gc.id=ce.competitor_id
                        join event as e
								 on ce.event_id=e.id
                        join sport as  s
                                 on e.sport_id=s.id
                        join medal as m
                                 on ce.medal_id=m.id
                         join person_region as pr
                                 on pr.person_id=gc.person_id
                         join noc_region as nr
                                 on pr.region_id=nr.id
                      where medal_name<>'NA'
                      group by 
                            g.games_year,
                        g.season,
                        s.sport_name,
                        nr.region_name 
                ),
  ranked_dominance as(
               select *,
                     dense_rank() over (partition by games_year,season,sport_name order by medal_count desc) as medal_dominance
				 from 
                    sport_yearly_domenance
                  )
 select *
     from ranked_dominance
  where    
    medal_dominance<=1;

--                                                    SUMMARY
-- >> The analysis identifies dominant countries or regions in specific sports by ranking them based on medal counts across Olympic years and seasons. 
-- The results reveal that certain nations consistently outperform others in particular sports, demonstrating long-term competitive strength and specialization.
-- At the same time, variations across years highlight shifts in dominance and increasing global competition.<<



##-- What factors contribute to the success or performance of participants from different countries?


WITH country_base AS (
    SELECT
        g.games_year,
        g.season,
        nr.region_name AS country,
        COUNT(DISTINCT gc.person_id) AS athlete_count,
        COUNT( m.id) AS total_medals,
        COUNT(DISTINCT s.id) AS sports_participated
    FROM games g
    JOIN games_competitor gc 
        ON g.id = gc.games_id
    JOIN person_region pr 
        ON gc.person_id = pr.person_id
    JOIN noc_region nr 
        ON pr.region_id = nr.id
    JOIN competitor_event ce 
        ON gc.id = ce.competitor_id
     JOIN medal m 
        ON ce.medal_id = m.id
     JOIN event e 
        ON ce.event_id = e.id
     JOIN sport s 
        ON e.sport_id = s.id
 where m.medal_name<>'NA'
    GROUP BY
        g.games_year,
        g.season,
        nr.region_name
),
efficiency_metrics AS (
    SELECT
        games_year,
        season,
        country,
        athlete_count,
        total_medals,
        sports_participated,
        ROUND(total_medals * 1.0 / NULLIF(athlete_count, 0), 3)
            AS medals_per_athlete,
        ROUND(total_medals * 1.0 / NULLIF(sports_participated, 0), 3)
            AS medals_per_sport
    FROM country_base
)
SELECT
    games_year,
    season,
    country,
    athlete_count,
    sports_participated,
    total_medals,
    medals_per_athlete,
    medals_per_sport
FROM efficiency_metrics
ORDER BY games_year, season, total_medals DESC;



    
   


## Are there any countries that consistently perform well in multiple Olympic editions?

   with yearly_count_medal as(
            select distinct
               g.games_year,
               g.season,
               nr.region_name as country,
               count(m.medal_name) as medal
		     from games as g
              join games_competitor as gc
                  on g.id=gc.games_id
              join competitor_event as ce
                  on gc.id=ce.competitor_id
              join medal as m
                  on ce.medal_id=m.id
			  join person_region as pr
				  on pr.person_id=gc.person_id
               join noc_region as nr
                  on pr.region_id=nr.id
               where m.medal_name<>'NA'
               group by 
                     g.games_year,
               g.season,
               nr.region_name
                  ),
  consistency_analysis as(
			select 
                  season,
                  country,
                  count(*) as times_of_country_participate,
                  round(avg(medal),2) as avg_medal,
                  round(stddev(medal),2) as medal_variation
               from yearly_count_medal
               group by season,country
     )

select 
    country,
    season,
	times_of_country_participate,
    avg_medal,
	medal_variation
 from consistency_analysis
 where times_of_country_participate>3 and 
         avg_medal>20      
 order by avg_medal desc,medal_variation asc ;





##Are there any sports or events that have a higher number of medalists from a specific region?
 with top_country as(
        with count_medal as (
                  select
                      s.sport_name,
                      e.event_name,
                      nr.region_name,
                      count(m.medal_name) as total_medal
                    from noc_region as nr
					join person_region as pr
                         on nr.id=pr.person_id
					join games_competitor as gc
                         on pr.person_id=gc.person_id
                    join competitor_event as ce
                         on gc.id=ce.competitor_id
                    join medal as m
                         on m.id=ce.medal_id
                    join event as e
                         on e.id=ce.event_id
                    join sport as s
                         on s.id=e.sport_id
					where m.medal_name<>'NA'
                    group by
                         s.sport_name,
                      e.event_name,
                      nr.region_name
                    )
  select *,
        row_number() over (partition by sport_name,event_name order by total_medal desc) as top_perfoming
      from 
         count_medal  
            )
   select *
    from top_country
    where top_perfoming<=1;
   
   
   
   
## What are some notable instances of unexpected or surprising medal wins?

with country_medal_history as(
                   select
                      nr.region_name as country,
                      count(m.medal_name) as total_medal,
                      count(distinct g.games_year) as editions
					from games as g
					join games_competitor as gc
                      on g.id=gc.games_id
					join person_region as pr using(person_id)
                    join noc_region as nr
                      on nr.id=pr.region_id
                    join competitor_event as ce
                      on gc.id=ce.competitor_id
                    join medal as m
                      on m.id=ce.medal_id
                    where m.medal_name<>'NA'
                    group by country  
                    ),
   unexpected_medals as(
				select 
                        g.games_year ,
                        g.season,
                        nr.region_name as country,
                        s.sport_name,
                        count(m.medal_name) as medal_won
				from games as g
					join games_competitor as gc
                      on g.id=gc.games_id
					join person_region as pr using(person_id)
                    join noc_region as nr
                      on nr.id=pr.region_id
                    join competitor_event as ce
                      on gc.id=ce.competitor_id
                    join medal as m
                      on m.id=ce.medal_id  
                    join event as e
					  on e.id=ce.event_id
                    join sport as s
                      on s.id=e.sport_id
                  where m.medal_name<>'NA'    
                  group by 
                      g.games_year ,
                        g.season,
                         country,
                        s.sport_name
               )
    select 
        u.games_year,
        u.season,
        u.country,
        u.sport_name,
        u.medal_won,
        round((c.total_medal*1.0/c.editions),2) as avg_medal_per_game
	from country_medal_history as c
     join   unexpected_medals as u using(country)
    where (c.total_medal*1.0/c.editions)<3
    order by u.medal_won desc,avg_medal_per_game;

## Are there any regions that have experienced significant growth or decline in Olympic participation?
  
with region_athelets_participate as(
			select
                   g.games_year,
                   g.season,
                   nr.region_name,
                   count( distinct p.id) as persent_year_athelets
				 from games as g
				 join games_competitor as gc
                    on g.id=gc.games_id
				 join person as p
                    on p.id=gc.person_id
                 join person_region as pr
                    on pr.person_id=p.id
                 join noc_region as nr
                    on nr.id=pr.region_id
                  group by   
                       g.games_year,
                       g.season,
                       nr.region_name  
               ),
athelets_change_participate as(             
                   select *,
                        lag(persent_year_athelets) over (partition by season,region_name order by games_year asc) as privious_year_athelets
                     from    
                         region_athelets_participate    
                )   

 select *,
     round((persent_year_athelets-privious_year_athelets)*100.0/persent_year_athelets,2) as percent_change
	from 			
       athelets_change_participate 
	where privious_year_athelets is not null
    order by abs(percent_change) desc;


##How do cultural or geographical factors influence the performance of regions in specific sports?

with region_wise_medal as(
                 select 
                    s.sport_name,
                    nr.region_name,
                    count(m.medal_name) as medal_country
				  from noc_region as nr
                  join person_region as pr
                    on nr.id=pr.region_id
				  join games_competitor as gc
                    on pr.person_id=gc.person_id
                  join competitor_event as ce
                    on gc.id=ce.competitor_id
                  join medal as m
                    on m.id=ce.medal_id
				  join event as e
					on e.id=ce.event_id
				  join sport as s
                    on s.id=e.sport_id
                 where m.medal_name<>'NA'
                 group by
                    s.sport_name,
                    nr.region_name
                    ),
sport_wise_medal as(
               select
                  s.sport_name,
                  count(m.medal_name) as sport_wise_medal
				 from medal as m
                 join competitor_event as ce
                   on m.id=ce.medal_id
                 join event as e
                   on e.id=ce.event_id
                 join sport as s
                   on s.id=e.sport_id
                 where m.medal_name<>'NA'   
				 group by 
                   s.sport_name
                 )
select 
   rm.region_name,
   rm.sport_name,
   round((rm.medal_country*100.0/sm.sport_wise_medal),2) as country_percent_overALL
 from region_wise_medal as rm
 join sport_wise_medal as sm using(sport_name)
 where (rm.medal_country*100.0/sm.sport_wise_medal)>40
 order by abs(country_percent_overALL) desc;
    

##  Are there any regions that have had a notable impact on the overall medal tally?

with region_wise_medal as(
                  select
                    nr.region_name,
                    count(m.medal_name) as country_wise_medal
                   from 
                     noc_region as nr
                     join person_region as pr
                       on nr.id=pr.region_id
                     join games_competitor as gc
                       on gc.person_id=pr.person_id
                     join competitor_event as ce
                       on gc.id=ce.competitor_id
                     join medal as m
                       on ce.medal_id=m.id
                   where m.medal_name<>'NA'    
                   group by 
                      nr.region_name
               ),
 total_medals as(
               select 
                 sum(country_wise_medal) as total_medalOFolympic
                 from region_wise_medal
                 )
 select 
     rm.*,
     round((rm.country_wise_medal*100/tm.total_medalOFolympic),2) as medal_share_percent
 from region_wise_medal as rm
    cross join total_medals as tm
 order by abs(medal_share_percent) desc;   
      
           
