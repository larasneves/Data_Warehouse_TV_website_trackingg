use anime_dimensional;
drop table if exists temp_studio;
drop table if exists studio;
drop table if exists bridge_studio;
drop table if exists split_studio;

CREATE TABLE studio (
    studio_id INT auto_increment primary key,
    studio VARCHAR(50)
);
create table temp_studio (
	anime_id_mal int,
	studio_group_id int,
	studio_id int,
	weight double,
	PRIMARY KEY (anime_id_mal, studio_group_id, studio_id)
);
create table bridge_studio (
	studio_group_id int,
	studio_id int,
	weight double,
	PRIMARY KEY (studio_group_id, studio_id),
    FOREIGN KEY (studio_id) REFERENCES studio(studio_id)
);

create table split_studio as (
	with recursive numbers_cte (n, studio, initial_studio, anime_id) as (
	    select 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(a.studio, ',', 1), ',', -1)) as studio, a.studio, a.anime_id
	    from anime.anime a
	    union all
	    select ncte.n + 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_studio, ',', ncte.n + 1), ',', -1)) as studio, ncte.initial_studio, ncte.anime_id
	    from numbers_cte ncte
	    where TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_studio, ',', ncte.n + 1), ',', -1)) != TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_studio, ',', ncte.n), ',', -1))
	)
	SELECT studio, anime_id as anime_id_mal FROM numbers_cte
);

insert into studio (studio)
select distinct studio
from split_studio
where studio != "";

insert into temp_studio
select distinct sg.anime_id_mal, ag.group_id, g.studio_id, 1 / ag.n_studios
from (
	select
		sg.anime_id_mal,
		dense_rank() over (order by group_concat(g.studio order by g.studio)) as group_id,
		count(g.studio) as n_studios
	from anime_dimensional.split_studio sg
	join anime_dimensional.studio g on g.studio = sg.studio
	group by sg.anime_id_mal
) as ag
join anime_dimensional.split_studio sg on sg.anime_id_mal = ag.anime_id_mal
join studio g on sg.studio = g.studio;

insert into bridge_studio
select distinct studio_group_id, studio_id, weight
from temp_studio;

drop table if exists anime_dimensional.split_studio;
