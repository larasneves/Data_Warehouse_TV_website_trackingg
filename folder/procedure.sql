CREATE DEFINER=root@localhost PROCEDURE anime_dimensional.split_countries()
begin
	-- Variables
	declare done int default false;
	DECLARE v_id INT;
    DECLARE v_country VARCHAR(255);
    DECLARE v_split_country VARCHAR(255);
    DECLARE cur1 CURSOR FOR select u.user_id, u.location FROM anime.user u where u.location is not null and u.location != "";
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    -- Error Handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;  -- Rollback changes in case of errors
        RESIGNAL;  -- Propagate the error for visibility
    END;

    -- Temporary Table Creation
    drop table if exists anime_dimensional.split_country;
    CREATE TABLE IF NOT EXISTS anime_dimensional.split_country (
        user_id INT,
        country VARCHAR(255)
    );

    START TRANSACTION;  -- Ensure changes are atomic

    OPEN cur1;

    read_loop: LOOP
	    IF done THEN
            LEAVE read_loop;
        END IF;

        FETCH cur1 INTO v_id, v_country;

        SET v_split_country = '';

        -- Iterate over comma-separated values
        WHILE LOCATE(',', v_country) > 0 DO
            SET v_split_country = SUBSTRING_INDEX(v_country, ',', 1);
            SET v_country = SUBSTRING(v_country, LOCATE(',', v_country) + 1);
            set v_split_country = upper(v_split_country);

            INSERT INTO anime_dimensional.split_country (user_id, country)
            VALUES (v_id, TRIM(v_split_country)); -- TRIM to remove leading/trailing spaces
        END WHILE;

        -- Handle the last country remaining
        set v_country = upper(v_country);
        INSERT INTO anime_dimensional.split_country (user_id, country)
        VALUES (v_id, TRIM(v_country));



    END LOOP;

    CLOSE cur1;

    COMMIT;  -- Commit the changes
END;