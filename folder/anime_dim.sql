use anime_dimensional;
drop table if exists anime;

create table anime (
  anime_id int auto_increment primary key,
  anime_id_mal int,
  title text,
  title_japanese text,
  image_url text,
  anime_type text,
  source text,
  episodes int,
  status text,
  aired_from date,
  aired_to date,
  duration_minutes int,
  rating text,
  broadcast text,
  opening_theme text,
  ending_theme text,
  unique(anime_id_mal)
);

INSERT INTO anime (
	anime_id_mal,
	title,
    title_japanese,
    image_url,
    anime_type,
    source,
    episodes,
    status,
    aired_from,
    aired_to,
    duration_minutes,
    rating,
    score,
    scored_by,
    anime_rank,
    popularity,
    members,
    favourites,
    broadcast,
    opening_theme,
    ending_theme
)
select
	anime_id,
    title,
    title_japanese,
    image_url,
    anime_type,
    source,
    episodes,
    status,
    CASE 
        WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(aired, "'from': '", -1),"'",1) REGEXP '[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN DATE(SUBSTRING_INDEX(SUBSTRING_INDEX(aired, "'from': '", -1),"'",1))
        ELSE NULL
    END AS aired_from,
    CASE 
        WHEN LENGTH(SUBSTRING_INDEX(aired, "'to': '", -1)) > 12 THEN NULL
        WHEN SUBSTRING_INDEX(SUBSTRING_INDEX(aired, "'to': '", -1),"'",1) REGEXP '[0-9]{4}-[0-9]{2}-[0-9]{2}' THEN DATE(SUBSTRING_INDEX(SUBSTRING_INDEX(aired, "'to': '", -1),"'",1))
        ELSE NULL
    END AS aired_to,
    CASE
        WHEN duration LIKE '%hr.% min.%' THEN
            (SUBSTRING_INDEX(duration, ' hr.', 1) * 60) + SUBSTRING_INDEX(SUBSTRING_INDEX(duration, ' hr. ', -1), ' min.', 1)
        WHEN duration LIKE '%hr.%' THEN
            SUBSTRING_INDEX(duration, ' hr.', 1) * 60
        WHEN duration LIKE '%min.%' THEN
            SUBSTRING_INDEX(duration, ' min.', 1)
    END AS duration,
    rating,
    broadcast,
    opening_theme,
    ending_theme
from anime.anime ;