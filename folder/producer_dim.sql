use anime_dimensional;
drop table if exists temp_producer;
drop table if exists producer;
drop table if exists bridge_producer;
drop table if exists split_producer;

CREATE TABLE producer (
    producer_id INT auto_increment primary key,
    producer VARCHAR(50)
);
create table temp_producer (
	anime_id_mal int,
	producer_group_id int,
	producer_id int,
	weight double,
	PRIMARY KEY (anime_id_mal, producer_group_id, producer_id)
);
create table bridge_producer (
	producer_group_id int,
	producer_id int,
	weight double,
	PRIMARY KEY (producer_group_id, producer_id),
    FOREIGN KEY (producer_id) REFERENCES producer(producer_id)
);

create table split_producer as(
	with recursive numbers_cte (n, producer, initial_producer, anime_id) as (
	    select 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(a.producer, ',', 1), ',', -1)) as producer, a.producer, a.anime_id
	    from anime.anime a
	    union all
	    select ncte.n + 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_producer, ',', ncte.n + 1), ',', -1)) as producer, ncte.initial_producer, ncte.anime_id
	    from numbers_cte ncte
	    where TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_producer, ',', ncte.n + 1), ',', -1)) != TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_producer, ',', ncte.n), ',', -1))
	)
	SELECT producer, anime_id as anime_id_mal FROM numbers_cte
);

insert into producer (producer)
select distinct producer
from split_producer
where producer != "";

insert into temp_producer
select distinct sg.anime_id_mal, ag.group_id, g.producer_id, 1 / ag.n_producers
from (
	select
		sg.anime_id_mal,
		dense_rank() over (order by group_concat(g.producer order by g.producer)) as group_id,
		count(g.producer) as n_producers
	from anime_dimensional.split_producer sg
	join anime_dimensional.producer g on g.producer = sg.producer
	group by sg.anime_id_mal
) as ag
join anime_dimensional.split_producer sg on sg.anime_id_mal = ag.anime_id_mal
join producer g on sg.producer = g.producer;

insert into bridge_producer
select distinct producer_group_id, producer_id, weight
from temp_producer;

drop table if exists anime_dimensional.split_producer;
