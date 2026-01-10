# Setup our staging tables
DROP TABLE IF EXISTS bref_pitcher_data_staging;
DROP TABLE IF EXISTS bref_batter_data_staging;

CREATE TABLE bref_pitcher_data_staging LIKE bref_pitcher_data;
CREATE TABLE bref_batter_data_staging LIKE bref_batter_data;

INSERT bref_pitcher_data_staging
SELECT *
FROM bref_pitcher_data;

INSERT bref_batter_data_staging
SELECT *
FROM bref_batter_data;

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

# Should only have 'ATH'
# SELECT *
# FROM bref_batter_data_staging
# WHERE team = 'ATH'
# OR    team = 'OAK';
# SELECT *
# FROM bref_pitcher_data_staging
# WHERE team = 'ATH'
# OR    team = 'OAK';