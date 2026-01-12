# Combines tables to aggregate the separate data from Fangraphs and Baseball-Reference
# For each type: Team, Batters, Pitchers
# We just want ONE table, and since this is historical data, it will save us a lot of
# computation time to run this aggregation once
DROP TABLE IF EXISTS combined_pitcher_data;
CREATE TABLE combined_pitcher_data AS (
	SELECT
		fg.season,
        fg.team,
        fg.MLBAMID,
        fg.player,
        fg.fWAR,
        bref.bWAR
    FROM fg_pitcher_data_staging AS fg
		JOIN bref_pitcher_data_staging AS bref
			ON fg.season = bref.season
			AND fg.team = bref.team
			AND fg.MLBAMID = bref.MLBAMID
			AND fg.player = bref.player
);

DROP TABLE IF EXISTS combined_batter_data;
CREATE TABLE combined_batter_data AS (
	SELECT
		fg.season,
        fg.team,
        fg.MLBAMID,
        fg.player,
        fg.fWAR,
        bref.bWAR
    FROM fg_batter_data_staging AS fg
        JOIN bref_batter_data_staging AS bref
			ON fg.season = bref.season
			AND fg.team = bref.team
			AND fg.MLBAMID = bref.MLBAMID
			AND fg.player = bref.player
);

DROP TABLE IF EXISTS combined_team_pitching;
CREATE TABLE combined_team_pitching AS (
	SELECT
		bref.season,
        bref.team,
        bref.team_name,
        bref.`Runs Allowed/Game`,
        bref.ERA,
        bref.`ERA+`,
        fg.`ERA-`,
        fg.FIP
    FROM bref_team_pitching_staging bref
        JOIN fg_team_pitching_staging AS fg
			ON bref.season = fg.season
            AND bref.team = fg.team
);

DROP TABLE IF EXISTS combined_team_batting;
CREATE TABLE combined_team_batting AS (
	SELECT
		bref.season,
        bref.team,
        bref.team_name,
        bref.`Runs/Game`,
        bref.OPS,
        bref.`OPS+`,
        fg.`wRC+`
    FROM bref_team_batting_staging bref
        JOIN fg_team_batting_staging AS fg
			ON bref.season = fg.season
            AND bref.team = fg.team
);


SELECT * FROM combined_pitcher_data LIMIT 3000;
SELECT * FROM combined_batter_data LIMIT 3000;
SELECT * FROM combined_team_pitching;
SELECT * FROM combined_team_batting;
SELECT * FROM mlb_standings_combined;

# Finalizing our tables into marts