use anime_dimensional;
drop table if exists anime_stats;

create table anime_stats (
    anime_id int not null,
    season_id int not null,
    number_views int not null,
    number_ratings int not null,
    score_rank int,
    score double,
    season_views int,
    season_ratings int,
    season_popularity_rank int,
    foreign key (anime_id) references anime(anime_id),
    foreign key (season_id) references seasons(season_id)
);

insert into anime_stats
with season_views_rank as (
    select distinct
        t.anime_id,
        t.season_id,
        t.season_views,
        rank() over(partition by t.season_id order by t.season_views desc) as season_popularity_rank
    from (
        select
            t.anime_id,
            t.season_id,
            count(distinct t1.user_id) as season_views
        FROM (
            SELECT a.anime_id, s.season_id, s.start_date
            FROM anime a
            CROSS JOIN (
                select season_id, start_date
                from seasons
                where year(start_date) > 1997 and year(start_date) < 2020
            ) as s
        ) as t
        LEFT JOIN (
            select i.anime_id, i.status, s.season_id , i.user_id
            from interactions i
            join days d on i.date_id = d.date_id
            JOIN seasons s on STR_TO_DATE(concat(d.year_number, "-", d.month_number, "-", d.day_number), '%Y-%m-%d')
                                between s.start_date and s.end_date
            where i.score > 0
        ) as t1 on t.anime_id = t1.anime_id and
              t1.season_id = t.season_id and
              t1.status = "completed"
        group by t.anime_id, t.season_id
    ) as t
),
score_rank as (
    select distinct
        anime_id, season_id,
        score,
        CASE
            WHEN score IS NULL THEN NULL  -- Assign NULL rank if score is NULL
            ELSE rank() over (partition by season_id order by score desc)
        END as score_rank
    from (
        SELECT
            t.anime_id,
            t.season_id,
            avg(t1.score) over (partition by t.anime_id order by t.start_date) as score
        FROM (
            SELECT a.anime_id, s.season_id, s.start_date
            FROM anime a
            CROSS JOIN (
                select season_id, start_date
                from seasons
                where year(start_date) > 1997 and year(start_date) < 2020
            ) as s
        ) as t
        LEFT JOIN (
            select i.anime_id, i.score, s.season_id
            from interactions i
            join days d on i.date_id = d.date_id
            JOIN seasons s on STR_TO_DATE(concat(d.year_number, "-", d.month_number, "-", d.day_number), '%Y-%m-%d')
                                between s.start_date and s.end_date
            where i.score > 0
        ) as t1 on t.anime_id = t1.anime_id and
              t1.season_id = t.season_id
    ) as t
),
number_views as (
    select
        t.anime_id,
        t.season_id,
        sum(count(distinct t1.user_id)) over (partition by t.anime_id order by t.start_date) as n_views
    FROM (
        SELECT a.anime_id, s.season_id, s.start_date
        FROM anime a
        CROSS JOIN (
            select season_id, start_date
            from seasons
            where year(start_date) > 1997 and year(start_date) < 2020
        ) as s
    ) as t
    LEFT JOIN (
        select i.anime_id, i.user_id, i.status, s.season_id
        from interactions i
        join days d on i.date_id = d.date_id
        JOIN seasons s on STR_TO_DATE(concat(d.year_number, "-", d.month_number, "-", d.day_number), '%Y-%m-%d')
                            between s.start_date and s.end_date
    ) as t1 on t.anime_id = t1.anime_id and
          t1.season_id = t.season_id and
          t1.status = 'completed'
    group by t.anime_id, t.season_id
),
ratings as (
    select distinct
        t.anime_id,
        sum(t.saw_anime) over (partition by t.anime_id order by t.start_date) as n_ratings,
        t.season_id,
        sum(t.saw_anime) over (partition by t.anime_id, t.season_id) as season_ratings
    from (
        select
            t.anime_id,
            t1.user_id,
            t.season_id,
            t.start_date,
            case when count(t1.score) > 0 then 1 else 0 end as saw_anime
        FROM (
            SELECT a.anime_id, s.season_id, s.start_date
            FROM anime a
            CROSS JOIN (
                select season_id, start_date
                from seasons
                where year(start_date) > 1997 and year(start_date) < 2020
            ) as s
        ) as t
        LEFT JOIN (
            select i.anime_id, i.user_id, i.status, s.season_id , i.score
            from interactions i
            join days d on i.date_id = d.date_id
            JOIN seasons s on STR_TO_DATE(concat(d.year_number, "-", d.month_number, "-", d.day_number), '%Y-%m-%d')
                                between s.start_date and s.end_date
        ) as t1 on t.anime_id = t1.anime_id and
             t1.season_id = t.season_id and
             t1.score > 0 and
             t1.status = "completed"
        group by t.anime_id, t1.user_id, t.season_id, t.start_date
    ) as t
)
select
    n.anime_id,
    n.season_id,
    n.n_views,
    r.n_ratings,
    sr.score_rank,
    sr.score,
    svr.season_views,
    r.season_ratings,
    svr.season_popularity_rank
from number_views n
join ratings r on n.anime_id = r.anime_id and n.season_id = r.season_id
join score_rank sr on n.anime_id = sr.anime_id and n.season_id = sr.season_id
join season_views_rank svr on n.anime_id = svr.anime_id and n.season_id = svr.season_id

