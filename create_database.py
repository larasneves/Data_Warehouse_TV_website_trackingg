import sqlalchemy


if __name__ == "__main__":
    host = "localhost"
    user = "root"
    passwd = "lolpenta69"
    database_uri = f"mysql://{user}:{passwd}@{host}:3306/"
    engine = sqlalchemy.create_engine(database_uri)

    with engine.connect() as conn:
        with conn.begin():
            query = """
                drop database if exists anime_dimensional;
                create database if not exists anime_dimensional;
            """
            query = sqlalchemy.text(query)
            conn.execute(query)

    files = (
        "procedure.sql",
        "anime_dim.sql",
        "time_dim.sql",
        "user_dim.sql",
        "genre_dim.sql",
        "studio_dim.sql",
        "licensor_dim.sql",
        "producer_dim.sql",
        "country_dim.sql",
        "interaction.sql",
        "user_evolution.sql",
        "anime_stats.sql",
    )
    files = files + ("remove_temp.sql",)

    for file in files:
        print(file)
        with open("DW/sql_scripts/" + file, "r") as f:
            query = sqlalchemy.text(f.read())

        with engine.connect() as conn:
            with conn.begin():
                conn.execute(query)
