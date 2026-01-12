# Setup our staging tables
DROP TABLE IF EXISTS bref_pitcher_data_staging;
DROP TABLE IF EXISTS bref_batter_data_staging;
DROP TABLE IF EXISTS bref_team_pitching_staging;
DROP TABLE IF EXISTS bref_team_batting_staging;

CREATE TABLE bref_pitcher_data_staging LIKE bref_pitcher_data;
CREATE TABLE bref_batter_data_staging LIKE bref_batter_data;
CREATE TABLE bref_team_pitching_staging LIKE bref_team_pitching;
CREATE TABLE bref_team_batting_staging LIKE bref_team_batting;

INSERT bref_pitcher_data_staging
SELECT *
FROM bref_pitcher_data;

INSERT bref_batter_data_staging
SELECT *
FROM bref_batter_data;

INSERT bref_team_pitching_staging
SELECT *
FROM bref_team_pitching;

INSERT bref_team_batting_staging
SELECT *
FROM bref_team_batting;

# Working on the individual data first
# Standardize the columns to match the Fangraphs data
ALTER TABLE bref_pitcher_data_staging
	RENAME COLUMN year_ID TO season,
    RENAME COLUMN team_ID TO team,
    RENAME COLUMN mlb_ID TO MLBAMID,
    RENAME COLUMN name_common TO player,
    RENAME COLUMN lg_ID TO league,
    RENAME COLUMN WAR to bWAR;

ALTER TABLE bref_batter_data_staging
	RENAME COLUMN year_ID TO season,
    RENAME COLUMN team_ID TO team,
    RENAME COLUMN mlb_ID TO MLBAMID,
    RENAME COLUMN name_common TO player,
    RENAME COLUMN lg_ID TO league,
    RENAME COLUMN WAR to bWAR;

# Check for duplicates
WITH duplicate_pitchers AS
(
	SELECT *,
    ROW_NUMBER() OVER (
		PARTITION BY player, MLBAMID, season, team, league, bWAR
    ) AS row_num
    FROM bref_batter_data_staging
)
SELECT *
FROM duplicate_pitchers
WHERE row_num > 1;

WITH duplicate_batters AS
(
	SELECT *,
    ROW_NUMBER() OVER (
		PARTITION BY player, MLBAMID, season, team, league, bWAR
    ) AS row_num
    FROM bref_pitcher_data_staging
)
SELECT *
FROM duplicate_batters
WHERE row_num > 1;

# Check if we have any invalid/extra team abbrevations
WITH teams AS (
    SELECT DISTINCT(team)
    FROM bref_pitcher_data_staging
    WHERE team IS NOT NULL

    UNION

    SELECT DISTINCT(team)
    FROM bref_batter_data_staging
    WHERE team IS NOT NULL
)
SELECT team, ROW_NUMBER() OVER (ORDER BY team) AS row_num
FROM teams;

# Same as Fangraphs, standardize ATH -> OAK
UPDATE bref_pitcher_data_staging
SET team = 'OAK'
WHERE team = 'ATH';

UPDATE bref_batter_data_staging
SET team = 'OAK'
WHERE team = 'ATH';

# Now working on the team tables
ALTER TABLE bref_team_pitching_staging
	RENAME COLUMN team_abbrev TO team,
    RENAME COLUMN runs_allowed_per_game TO `Runs Allowed/Game`,
    RENAME COLUMN earned_run_avg TO ERA,
    RENAME COLUMN earned_run_avg_plus TO `ERA+`;

ALTER TABLE bref_team_batting_staging
	RENAME COLUMN team_abbrev to team,
    RENAME COLUMN runs_per_game TO `Runs/Game`,
    RENAME COLUMN onbase_plus_slugging TO OPS,
    RENAME COLUMN onbase_plus_slugging_plus TO `OPS+`;
    
# Standardize ATH -> OAK
UPDATE bref_team_pitching_staging
SET team = 'OAK', team_name = 'Oakland Athletics'
WHERE team = 'ATH';

UPDATE bref_team_batting_staging
SET team = 'OAK', team_name = 'Oakland Athletics'
WHERE team = 'ATH';

# Working on the standings table
DROP TABLE IF EXISTS mlb_standings_combined;

CREATE TABLE mlb_standings_combined LIKE mlb_team_win_loss;

INSERT mlb_standings_combined
SELECT *
FROM mlb_team_win_loss;

# We want to have the league and division placement in our standings
ALTER TABLE mlb_standings_combined
	RENAME COLUMN Tm TO team,
	ADD COLUMN league VARCHAR(2),
    ADD COLUMN divisional_placement BIGINT;

UPDATE mlb_standings_combined
SET team = 'Oakland Athletics'
WHERE team = 'Athletics';
    
# Add the league to the standings table
UPDATE mlb_standings_combined standings
JOIN (
	SELECT DISTINCT t2.team, t2.team_name, t1.league
	FROM bref_batter_data_staging t1
	JOIN bref_team_batting_staging t2
		ON t1.team = t2.team
) AS league_mapping
	ON standings.team = league_mapping.team_name
SET standings.league = league_mapping.league
WHERE standings.league IS NULL;

WITH division_standings AS (
	SELECT *,
    ROW_NUMBER() OVER (
		PARTITION BY season, league, division
        ORDER BY GB
    ) as division_placement
	FROM mlb_standings_combined
)
SELECT *
FROM division_standings
WHERE league = 'AL' AND division = 'West' AND season = 2023;

UPDATE mlb_standings_combined standings
JOIN (
	SELECT *,
    ROW_NUMBER() OVER (
		PARTITION BY season, league, division
        ORDER BY GB
    ) AS division_placement
	FROM mlb_standings_combined
) AS division_standings
ON standings.team = division_standings.team
	AND standings.season = division_standings.season
SET standings.divisional_placement = division_standings.division_placement;

# Check the finalized tables
SELECT * FROM bref_team_pitching_staging;
SELECT * FROM bref_team_batting_staging;
SELECT * FROM mlb_standings_combined ORDER BY season, division, league, GB;