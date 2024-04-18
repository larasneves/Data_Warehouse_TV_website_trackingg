use anime_dimensional;
drop table if exists interactions;

create table temp_bridges(
	anime_id int primary key,
	genre_group_id int,
	studio_group_id int,
	licensor_group_id int,
	producer_group_id int
);
insert into temp_bridges
select distinct a.anime_id, tg.genre_group_id, ts.studio_group_id, tl.licensor_group_id, tp.producer_group_id
from anime a
left join temp_genre tg on tg.anime_id_mal = a.anime_id_mal
left join temp_studio ts on a.anime_id_mal = ts.anime_id_mal
left join temp_licensor tl on a.anime_id_mal = tl.anime_id_mal
left join temp_producer tp on a.anime_id_mal = tp.anime_id_mal;

create table interactions(
	user_id int,
	anime_id int,
	date_id int,
	genre_group_id int,
	studio_group_id int,
	licensor_group_id int,
	producer_group_id int,
	score int,
	status varchar(50),
	watched_episodes int NOT NULL,
	FOREIGN KEY (anime_id) REFERENCES anime(anime_id),
	FOREIGN KEY (user_id) REFERENCES user(user_id),
    FOREIGN KEY (date_id) REFERENCES days(date_id),
    FOREIGN KEY (genre_group_id) REFERENCES bridge_genre(genre_group_id),
    FOREIGN KEY (licensor_group_id) REFERENCES bridge_licensor(licensor_group_id),
    FOREIGN KEY (producer_group_id) REFERENCES bridge_producer(producer_group_id),
    FOREIGN KEY (studio_group_id) REFERENCES bridge_studio(studio_group_id)
);
insert into interactions
select
    u.user_id,
    a.anime_id,
    d.date_id,
    tb.genre_group_id,
    tb.studio_group_id,
    tb.licensor_group_id,
    tb.producer_group_id,
    io.my_score,
    elt(io.my_status, "watching", "completed", "on hold", "dropped", NULL, "plan to watch"),
    io.my_watched_episodes
from anime.interaction_ops io
join (select anime_id, anime_id_mal from anime) a on a.anime_id_mal = io.anime_id
join `user` u on u.username = io.username
join temp_bridges tb on a.anime_id = tb.anime_id
left join anime_dimensional.days d on STR_TO_DATE(concat(d.year_number, " ", d.month_number, " ", d.day_number), "%Y %m %d") = case when io.my_status = 1 then io.my_start_date when io.my_status = 2 then io.my_finish_date else NULL end;