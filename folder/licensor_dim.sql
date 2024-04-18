use anime_dimensional;
drop table if exists temp_licensor;
drop table if exists licensor;
drop table if exists bridge_licensor;
drop table if exists split_licensor;

CREATE TABLE licensor (
    licensor_id INT auto_increment primary key,
    licensor VARCHAR(50)
);
create table temp_licensor (
	anime_id_mal int,
	licensor_group_id int,
	licensor_id int,
	weight double,
	PRIMARY KEY (anime_id_mal, licensor_group_id, licensor_id)
);
create table bridge_licensor (
	licensor_group_id int,
	licensor_id int,
	weight double,
	PRIMARY KEY (licensor_group_id, licensor_id),
    FOREIGN KEY (licensor_id) REFERENCES licensor(licensor_id)
);

create table split_licensor as(
	with recursive numbers_cte (n, licensor, initial_licensor, anime_id) as (
	    select 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(a.licensor, ',', 1), ',', -1)) as licensor, a.licensor, a.anime_id
	    from anime.anime a
	    union all
	    select ncte.n + 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_licensor, ',', ncte.n + 1), ',', -1)) as licensor, ncte.initial_licensor, ncte.anime_id
	    from numbers_cte ncte
	    where TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_licensor, ',', ncte.n + 1), ',', -1)) != TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_licensor, ',', ncte.n), ',', -1))
	)
	SELECT licensor, anime_id as anime_id_mal FROM numbers_cte
);

insert into licensor (licensor)
select distinct licensor
from split_licensor
where licensor != "";

insert into temp_licensor
select distinct sg.anime_id_mal, ag.group_id, g.licensor_id, 1 / ag.n_licensors
from (
	select
		sg.anime_id_mal,
		dense_rank() over (order by group_concat(g.licensor order by g.licensor)) as group_id,
		count(g.licensor) as n_licensors
	from anime_dimensional.split_licensor sg
	join anime_dimensional.licensor g on g.licensor = sg.licensor
	group by sg.anime_id_mal
) as ag
join anime_dimensional.split_licensor sg on sg.anime_id_mal = ag.anime_id_mal
join licensor g on sg.licensor = g.licensor;

insert into bridge_licensor
select distinct licensor_group_id, licensor_id, weight
from temp_licensor;

drop table if exists anime_dimensional.split_licensor;
