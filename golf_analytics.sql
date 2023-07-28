-- **Project start.**

-- Creation of a table with the fields included in the CSV file.
CREATE TABLE pga_clean (
    Player_initial_last VARCHAR(50),
    tournament_id INT,
    player_id INT,
    hole_par INT,
    strokes INT,
    hole_DKP DECIMAL(10, 2),
    hole_FDP DECIMAL(10, 2),
    hole_SDP DECIMAL(10, 2),
    streak_DKP DECIMAL(10, 2),
    streak_FDP DECIMAL(10, 2),
    streak_SDP DECIMAL(10, 2),
    n_rounds INT,
    made_cut VARCHAR(10),
    pos INT,
    finish_DKP DECIMAL(10, 2),
    finish_FDP DECIMAL(10, 2),
    finish_SDP DECIMAL(10, 2),
    total_DKP DECIMAL(10, 2),
    total_FDP DECIMAL(10, 2),
    total_SDP DECIMAL(10, 2),
    player VARCHAR(50),
    tournament_name VARCHAR(100),
    course VARCHAR(100),
    date DATE,
    purse DECIMAL(12, 2),
    season INT,
    no_cut VARCHAR(10),
    Finish INT,
    sg_putt DECIMAL(5, 2),
    sg_arg DECIMAL(5, 2),
    sg_app DECIMAL(5, 2),
    sg_ott DECIMAL(5, 2),
    sg_t2g DECIMAL(5, 2),
    sg_total DECIMAL(5, 2));

-- Load of the CSV file into the created table.    
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/pga_data_clean.csv' INTO TABLE pga_clean
FIELDS terminated by ','
ENCLOSED BY '"';

-- Table dimensions
SELECT COUNT(*) AS rows_num FROM pga_clean;
SELECT COUNT(*) AS cols_num FROM information_schema.columns WHERE table_name = 'pga_clean';

-- Table fields info
DESCRIBE pga_clean;

-- Uncheck the SAFE UPDATES mode to execute the update in the next query.
SET SQL_SAFE_UPDATES = 0;

-- Update of the field pos to include only numeric values.
UPDATE pga_clean
SET pos = REGEXP_REPLACE(pos, '[^0-9]', '');

-- Activate the SAFE UPDATES mode back.
SET SQL_SAFE_UPDATES = 1;

-- Possible values taken in some fields of interest.
SELECT DISTINCT player FROM pga_clean;
SELECT DISTINCT hole_par FROM pga_clean;
SELECT DISTINCT n_rounds FROM pga_clean;
SELECT DISTINCT made_cut FROM pga_clean;
SELECT DISTINCT tournament_name FROM pga_clean;
SELECT DISTINCT course FROM pga_clean;
SELECT DISTINCT purse FROM pga_clean;
SELECT DISTINCT season FROM pga_clean;
SELECT DISTINCT pos FROM pga_clean;

-- Percentage of the total of some fields.
SELECT player, count(*) total_participations, ROUND((COUNT(*) / (SELECT COUNT(*) FROM pga_clean)) * 100, 1) AS pct_participations
FROM pga_clean GROUP BY 1 ORDER BY 3 DESC;
SELECT tournament_name, count(*) total_tours, ROUND((COUNT(*) / (SELECT COUNT(*) FROM pga_clean)) * 100, 1) AS pct_tours
FROM pga_clean GROUP BY 1 ORDER BY 3 DESC;

SELECT course, count(*) count_course, ROUND((COUNT(*) / (SELECT COUNT(*) FROM pga_clean)) * 100, 1) AS pct_course
FROM pga_clean GROUP BY 1 ORDER BY 3 DESC;

SELECT season, count(*) season_parts, ROUND((COUNT(*) / (SELECT COUNT(*) FROM pga_clean)) * 100, 1) AS pct_season_parts
FROM pga_clean GROUP BY 1 ORDER BY 3 DESC;

SELECT pos, count(*) count_pos, ROUND((COUNT(*) / (SELECT COUNT(*) FROM pga_clean)) * 100, 1) AS pct_pos
FROM pga_clean GROUP BY 1 ORDER BY 3 DESC;

-- SIMPLE ANALYSIS START
-- Descending total number of rounds played by player.
SELECT player, sum(n_rounds) Total_Rounds
from pga_clean
group by player
order by Total_Rounds DESC;

-- Descending total of wins, first and last win by player
select player, count(player) n_wins, MIN(date) AS first_win, MAX(date) AS last_win
from pga_clean pc
where pos = '1'
group by player
order by n_wins DESC;

-- Descending total of times in top10 by player.
select player, count(*) n_top10 
from pga_clean
where pos <= 10
group by player
order by n_top10 DESC;

-- Descending purse by tour and season.
SELECT tournament_name, season, purse
FROM pga_clean
GROUP BY tournament_name, season
ORDER BY purse DESC;

-- SELECTIVE ANALYSIS STARTS
-- Change the quouted values for your preference values of player and tournament_name.
set @sel_player = 'Justin Thomas';
set @sel_tour = 'Tour Championship';

-- Descending times in top10 by tour of the selected player.
select player, tournament_name, count(tournament_name) tour_top10
from pga_clean
where pos <= 10 AND player = @sel_player
group by tournament_name
order by tour_top10 DESC;

-- Descending total of strokes gained and all other playing skills of the selected player.
select player, `sg_putt`, `sg_arg`, `sg_app`, `sg_ott`, `sg_t2g`, `sg_total`
from pga_clean
where player = @sel_player
order by sg_total DESC;

-- Highest strokes gained in all the playing skills of the selected player.
select player, MAX(sg_putt), MAX(sg_arg), MAX(sg_app), MAX(sg_ott), MAX(sg_t2g), MAX(sg_total)
from pga_clean
where player = @sel_player
order by sg_total DESC;

-- Total participations and times made cut of the selected player.
select pga_clean.player, count(*) times_made_cut, total_participations
from pga_clean
join (select player, count(*) n_parts from pga_clean group by player) player_parts
on pga_clean.player = player_parts.player
where pga_clean.player = @sel_player
AND made_cut = 1
order by times_made_cut DESC;

-- Descending total times in top10 by player in the selected tour.
select player, count(player) tour_10s, tournament_name
from pga_clean
where pos <= 10 AND tournament_name = @sel_tour
group by tournament_name, player
order by tour_10s DESC;
-- SELECTIVE ANALYSIS FINISHES


-- ADVANCED ANALYSIS
-- Descending total wins and number of wins of the same tour by player
SELECT total.player, tournament_name, tour_wins, total_wins
FROM (SELECT player, tournament_name, COUNT(*) AS tour_wins
FROM pga_clean
WHERE pos = 1
GROUP BY player, tournament_name
ORDER BY tour_wins DESC, tournament_name) tour
LEFT JOIN (SELECT player, count(*) total_wins from pga_clean where pos = 1 group by player) total
ON tour.player = total.player
ORDER BY  tour_wins DESC, total_wins DESC;

-- Descending the smallest difference in strokes from par, the course and the date on which the player made it
SELECT pc.player, pc.strokes, pc.hole_par, (pc.strokes - pc.hole_par) to_par, pc.tournament_name, pc.date
FROM pga_clean pc
JOIN (
    SELECT tournament_name, MIN(strokes) AS min_strokes, DATE, hole_par
    FROM pga_clean
    GROUP BY tournament_name
) t ON pc.tournament_name = t.tournament_name AND pc.strokes = t.min_strokes
WHERE pc.n_rounds >= 4
ORDER BY to_par;

-- Descending percentage of cuts passed and total participations by player
select pc.player, n_parts.participations, count(pc.player)/n_parts.participations pct_cuts_passed
from pga_clean pc
LEFT JOIN (select player, count(player) participations from pga_clean group by player) n_parts
on n_parts.player = pc.player
where made_cut ='1'
group by player
order by pct_cuts_passed DESC, participations DESC;

-- Descending total wins, participations and average of playing skills by player
SELECT pc.player, tt.part_tours, COUNT(pc.player) won_tours, AVG(strokes), AVG(sg_app), AVG(sg_arg), AVG(sg_ott), AVG(sg_putt), AVG(sg_t2g), AVG(sg_total)
FROM pga_clean pc
LEFT JOIN (SELECT player, COUNT(player) part_tours FROM pga_clean GROUP BY player) tt
ON pc.player = tt.player
WHERE POS = 1
GROUP BY player
ORDER BY won_tours DESC, AVG(sg_total) DESC;

-- Descending percentage of times in the top10. Returns the average difference from par per player
-- and the playing skills of players with above-average skills.
SELECT pc.player, COUNT(pc.player)/tt.part_tours perc10_tt, AVG(strokes)-AVG(hole_par) strokes,
AVG(sg_app), AVG(sg_arg), AVG(sg_ott), AVG(sg_putt), AVG(sg_t2g), AVG(sg_total)
FROM pga_clean pc
LEFT JOIN (SELECT player, COUNT(player) part_tours FROM pga_clean GROUP BY player) tt
ON pc.player = tt.player
WHERE POS <= 10
GROUP BY player
HAVING AVG(sg_app) > (SELECT AVG(sg_app) FROM pga_clean)
AND AVG(sg_arg) > (SELECT AVG(sg_arg) FROM pga_clean)
AND AVG(sg_ott) > (SELECT AVG(sg_ott) FROM pga_clean)
AND AVG(sg_putt) > (SELECT AVG(sg_putt) FROM pga_clean)
AND AVG(sg_t2g) > (SELECT AVG(sg_t2g) FROM pga_clean)
AND AVG(sg_total) > (SELECT AVG(sg_total) FROM pga_clean)
ORDER by perc10_tt DESC;

-- Ascending minimum strokes, season, tour and player
SELECT player, tournament_name, season, MIN(strokes) OVER(PARTITION BY player, tournament_name) AS min_strokes 
FROM pga_clean
WHERE n_rounds >= 4
ORDER BY min_strokes, season, tournament_name, player;





