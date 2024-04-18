use anime_dimensional;
drop table if exists split_country;
drop table if exists country;
drop table if exists temp_country;

create table country (
	country_id int auto_increment primary key,
	country text
);
create table temp_country (
    user_id_mal int,
    country text
);
create table split_country as (
	with recursive numbers_cte (n, country, initial_country, user_id_mal) as (
	    select 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(u.location, ',', 1), ',', -1)) as country, u.location, u.user_id
	    from anime.`user` u
	    union all
	    select ncte.n + 1, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_country, ',', ncte.n + 1), ',', -1)) as country, ncte.initial_country, ncte.user_id_mal
	    from numbers_cte ncte
	    where TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_country, ',', ncte.n + 1), ',', -1)) != TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(ncte.initial_country, ',', ncte.n), ',', -1))
	)
	SELECT country, user_id_mal FROM numbers_cte
);

insert into temp_country
select distinct user_id_mal, min(country)
from(
	select s.user_id_mal, c.name as country
	from split_country s
	join world.countries c on upper(c.name) =  s.country COLLATE utf8mb4_unicode_ci
	union
	select s.user_id_mal, c.name as country
	from split_country s
	join world.states st on upper(st.name) =  s.country COLLATE utf8mb4_unicode_ci
	join world.countries c on c.id = st.country_id
) as t
group by user_id_mal
having count(distinct country) = 1;

insert into country (country)
select distinct country
from temp_country
where country is not null or country != "";

drop table if exists split_country;