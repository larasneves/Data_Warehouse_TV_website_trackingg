/*

A - years_activity_age
B - user_country
C - users_per_country
D - avg_age_per_country
E - fav_genre_year
F - avg_score_year

*/
use anime_dimensional;
DROP TABLE IF EXISTS user_evolution;


call anime_dimensional.split_countries();


CREATE TABLE user_evolution(
    user_id integer,
    country_id integer,
    genre_id integer,
    year_id integer,
    age int,
    years_activity int,
    nr_users_per_country int,
    average_users_age_per_country int,
    average_score_per_user_per_year double,
    foreign key (user_id) references `user`(user_id),
    foreign key (country_id) references country(country_id),
    foreign key (genre_id) references genre(genre_id),
    foreign key (year_id) references years(year_id)
);

INSERT INTO user_evolution(user_id, country_id, genre_id, year_id, age, years_activity, nr_users_per_country,
average_users_age_per_country, average_score_per_user_per_year)

with years_activity_age as (
select
    u.user_id,
    FLOOR(DATEDIFF(current_date, join_date) / 365.25) AS years_activity,
    FLOOR(DATEDIFF(current_date, birth_date) / 365.25) AS age
from anime_dimensional.user u
),
user_country as (
	select sc.user_id, c2.country_id
	from anime_dimensional.split_country sc
	join world.countries c on upper(c.name) =  sc.country COLLATE utf8mb4_unicode_ci
	join anime_dimensional.country c2 on c2.country =c.name COLLATE utf8mb4_unicode_ci
	union
	select sc.user_id, c2.country_id
	from anime_dimensional.split_country sc
	join world.states st on upper(st.name) = sc.country COLLATE utf8mb4_unicode_ci
	join world.countries c on c.id = st.country_id
	join anime_dimensional.country c2 on c2.country =c.name COLLATE utf8mb4_unicode_ci

	order by user_id
),
users_per_country as (
	select user_country.country_id, count(user_country.user_id) as 'nr_users_per_country'
	from user_country
	group by country_id
),
avg_age_per_country as (
	select user_country.country_id, avg(years_activity_age.age) as 'average_users_age_per_country'
	from years_activity_age
	left join user_country on years_activity_age.user_id = user_country.user_id
	group by user_country.country_id
),
fav_genre_year as (
    select
    	t.user_id,
    	t.genre_id,
    	t.year_id
    from (
      select
        user_id,
        genre_id,
        d.year_id,
        sum(bg.weight) as genre_weight,
        row_number() over (partition by user_id, d.year_id order by sum(bg.weight) desc) as genre_rank
      from interactions i
      join bridge_genre bg on i.genre_group_id = bg.genre_group_id
      join days d on d.date_id = i.date_id
      group by user_id, genre_id, d.year_id
    ) t
    where t.genre_rank = 1
),
avg_score_year as (
    select
        u.user_id,
        d.year_id,
        avg(i.score) as avg_score_year
    from anime_dimensional.user u
    join anime_dimensional.interactions i on u.user_id = i.user_id
    join anime_dimensional.days d on d.date_id = i.date_id
    group by u.user_id, d.year_id
    order by user_id)



 select yea.user_id, uc.country_id, fgy.genre_id, fgy.year_id,yea.age,yea.years_activity, upc.nr_users_per_country, aapc.average_users_age_per_country,asy.avg_score_year
 from years_activity_age yea
 left join user_country uc on yea.user_id = uc.user_id
 left join users_per_country upc on upc.country_id = uc.country_id
 left join avg_age_per_country aapc on aapc.country_id = uc.country_id
 join fav_genre_year fgy on fgy.user_id = yea.user_id
 join avg_score_year asy on asy.user_id = fgy.user_id and asy.year_id=fgy.year_id

