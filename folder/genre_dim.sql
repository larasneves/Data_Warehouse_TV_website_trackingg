use anime_dimensional;
drop table if exists temp_genre;
drop table if exists genre;
drop table if exists bridge_genre;
drop table if exists split_genre;

CREATE TABLE genre (
    genre_id INT auto_increment primary key,
    genre VARCHAR(50)
);
create table temp_genre (
	anime_id_mal int,
	genre_group_id int,
	genre_id int,
	weight double,
	PRIMARY KEY (anime_id_mal, genre_group_id, genre_id)
);
create table bridge_genre (
	genre_group_id int,
	genre_id int,
	weight double,
	PRIMARY KEY (genre_group_id, genre_id),
    FOREIGN KEY (genre_id) REFERENCES genre(genre_id)
);

create table split_genre as(
	with recursive numbers_cte (n, genre, initial_genre, anime_id) as (
	    select 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(a.genre, ',', 1), ',', -1)) as genre, a.genre, a.anime_id
	    from anime.anime a
	    union all
	    select ncte.n + 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_genre, ',', ncte.n + 1), ',', -1)) as genre, ncte.initial_genre, ncte.anime_id
	    from numbers_cte ncte
	    where TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_genre, ',', ncte.n + 1), ',', -1)) != TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_genre, ',', ncte.n), ',', -1))
	)
	SELECT genre, anime_id as anime_id_mal FROM numbers_cte
);

insert into genre (genre)
select distinct genre
from split_genre
where genre != "";

insert into temp_genre
select distinct sg.anime_id_mal, ag.group_id, g.genre_id, 1 / ag.n_genres
from (
	select
		sg.anime_id_mal,
		dense_rank() over (order by group_concat(g.genre order by g.genre)) as group_id,
		count(g.genre) as n_genres
	from anime_dimensional.split_genre sg
	join anime_dimensional.genre g on g.genre = sg.genre
	group by sg.anime_id_mal
) as ag
join anime_dimensional.split_genre sg on sg.anime_id_mal = ag.anime_id_mal
join genre g on sg.genre = g.genre;

insert into bridge_genre
select distinct genre_group_id, genre_id, weight
from temp_genre;

drop table if exists anime_dimensional.split_genre;
