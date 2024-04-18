drop table if exists user;

CREATE TABLE user (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id_mal int,
    username VARCHAR(50),
    gender varchar(10),
    birth_date DATE,
    join_date DATE
);

INSERT INTO user (
    user_id_mal,
    username,
    gender,
    birth_date,
    join_date
)
SELECT
    user_id,
    username,
    gender,
    birth_date,
    join_date
from anime.`user` ;