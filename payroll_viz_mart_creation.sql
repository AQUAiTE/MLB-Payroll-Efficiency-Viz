# We want a one-stop shop for our needed data that the viz tool will be using
# SQL is much faster at JOINs and such computations than a viz tool, so it will save our 
# tool time/effort to instead join together all the necessary data here.

# First let's inspect the data we have
SELECT * FROM combined_pitcher_data LIMIT 3000; -- 2853 Rows
SELECT * FROM combined_batter_data LIMIT 3000; -- 2390 Rows
SELECT * FROM combined_team_pitching;
SELECT * FROM combined_team_batting;
SELECT * FROM mlb_standings_combined;

# The reasoning is outlined in the documentation, but these are the two marts we'll need
DROP TABLE IF EXISTS player_season_value_mart;
CREATE TABLE player_season_value_mart AS (
	(
		SELECT
			season,
            team,
            player,
            'pitcher' AS player_type,
            NULL AS position,
            fWAR,
            bWAR
		FROM combined_pitcher_data
    )
    UNION ALL
    (
		SELECT
			season,
            team,
            player,
            'batter' AS batter_type,
            position,
            fWAR,
            bWAR
            FROM combined_batter_data
    )
);
SELECT * FROM player_season_value_mart LIMIT 10000; -- Should be (and is) 5243 rows

DROP TABLE IF EXISTS team_season_summary_mart;
CREATE TABLE team_season_summary_mart AS (
	SELECT
		pitch.season	  AS season,
        pitch.team		  AS team,
        pitch.team_name   AS team_name,
        CONCAT(standings.league, ' ', standings.division) AS division,
		war.team_fWAR 	  AS fWAR,
        war.team_bWAR	  AS bWAR,
        standings.wins 	  AS wins,
        standings.losses  AS losses,
        standings.win_pct  AS win_pct,
        pitch.ERA 		  AS ERA,
        pitch.`ERA+`        AS `ERA+`,
        bat.`Runs/Game`   AS `Runs/Game`,
        bat.`wRC+`		  AS `wRC+`
    FROM combined_team_pitching pitch
    JOIN combined_team_batting bat
		ON pitch.season = bat.season
        AND pitch.team = bat.team
	JOIN mlb_standings_combined standings
		ON standings.season = pitch.season
        AND standings.team = pitch.team_name
	LEFT JOIN (
		SELECT
			season,
            team,
            SUM(fWAR) AS team_fWAR,
            SUM(bWAR) as team_bWAR
		FROM player_season_value_mart
        GROUP BY season, team
	) AS war
		ON war.season = pitch.season
        AND war.team = pitch.team
);
SELECT * FROM team_season_summary_mart ORDER BY season, division, wins DESC; -- Should be 150 rows
