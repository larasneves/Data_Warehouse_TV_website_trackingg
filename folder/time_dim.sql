use anime_dimensional;
drop table if exists days;
drop table if exists seasons;
drop table if exists seasons_test;
drop table if exists years;

create table anime_dimensional.days (
    date_id int auto_increment primary key,
	day_id int not null,
	day_number int not null,
	weekday_name varchar(10) not null,
	month_id int not null,
	month_number decimal(2,0) not null,
	year_id int not null,
	year_number decimal(4,0) not null,
	unique(year_number, month_number, day_number)
);
insert into anime_dimensional.days (
	year_number, month_number, day_number, weekday_name, day_id, month_id, year_id
)
select
	year(d.all_dates),
	month(d.all_dates),
	day(d.all_dates),
    elt(dayofweek(d.all_dates), "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Satuday"),
    dense_rank() over (order by day(d.all_dates)),
    dense_rank() over (order by month(d.all_dates)),
    dense_rank() over (order by year(d.all_dates))
from (
	select date(last_online) as all_dates from anime.`user`
	union
	select my_start_date as all_dates from anime.interaction_ops
	union
	select my_finish_date as all_dates from anime.interaction_ops
	) as d
where d.all_dates is not null;

create table years (
    year_id int primary key,
    year_number decimal(4,0) not null
);
insert into years (year_id, year_number)
select distinct d.year_id, d.year_number
from days d;

drop table if exists seasons;
CREATE TABLE seasons (
    season_id INT AUTO_INCREMENT PRIMARY KEY,
    season VARCHAR(10) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);
INSERT INTO seasons (season, start_date, end_date)
SELECT distinct
    elt(month_number, "Winter", "Winter", "Spring", "Spring", "Spring", "Summer", "Summer", "Summer", "Fall", "Fall", "Fall", "Winter") as season,
    CASE
        WHEN month_number in (1, 2) THEN STR_TO_DATE(CONCAT(year_number - 1, '-12-01'), '%Y-%m-%d')
        when month_number in (4, 5) THEN STR_TO_DATE(CONCAT(year_number, '-03-01'), '%Y-%m-%d')
        when month_number in (7, 8) THEN STR_TO_DATE(CONCAT(year_number, '-06-01'), '%Y-%m-%d')
        when month_number in (10, 11) THEN STR_TO_DATE(CONCAT(year_number, '-09-01'), '%Y-%m-%d')
        ELSE STR_TO_DATE(CONCAT(year_number, '-', month_number, '-01'), '%Y-%m-%d')
    END AS start_date,
    DATE_ADD(CASE
        WHEN month_number in (1, 2) THEN STR_TO_DATE(CONCAT(year_number - 1, '-12-01'), '%Y-%m-%d')
        when month_number in (4, 5) THEN STR_TO_DATE(CONCAT(year_number, '-03-01'), '%Y-%m-%d')
        when month_number in (7, 8) THEN STR_TO_DATE(CONCAT(year_number, '-06-01'), '%Y-%m-%d')
        when month_number in (10, 11) THEN STR_TO_DATE(CONCAT(year_number, '-09-01'), '%Y-%m-%d')
        ELSE STR_TO_DATE(CONCAT(year_number, '-', month_number, '-01'), '%Y-%m-%d')
    END, INTERVAL 3 MONTH) - INTERVAL 1 DAY AS end_date
FROM days;