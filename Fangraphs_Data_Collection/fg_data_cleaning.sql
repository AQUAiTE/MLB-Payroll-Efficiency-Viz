# Before running our FanGraphs data cleaning
DROP TABLE IF EXISTS fg_batter_data_staging;
DROP TABLE IF EXISTS fg_pitcher_data_staging;

# Verify we have the correct # of rows
SELECT *
FROM fg_batter_data
LIMIT 10000;
SELECT *
FROM fg_pitcher_data
LIMIT 10000;

# Stage our tables
CREATE TABLE fg_batter_data_staging LIKE fg_batter_data;
CREATE TABLE fg_pitcher_data_staging LIKE fg_pitcher_data;

INSERT fg_batter_data_staging
SELECT *
FROM fg_batter_data;

INSERT fg_pitcher_data_staging
SELECT *
FROM fg_pitcher_data;

# Standardize column names except for special types (fWAR and xMLBAMID)
# Adjust fWAR to be 1 decimal
ALTER TABLE fg_batter_data_staging
RENAME COLUMN Season TO season,
RENAME COLUMN team_name TO team,
RENAME COLUMN PlayerName TO player,
CHANGE COLUMN WAR fWAR DECIMAL(4, 1);

ALTER TABLE fg_pitcher_data_staging
RENAME COLUMN Season TO season,
RENAME COLUMN team_name TO team,
RENAME COLUMN PlayerName TO player,
CHANGE COLUMN WAR fWAR DECIMAL(4, 1);

# Check for duplicates
WITH duplicate_batters AS
(
	SELECT *,
    ROW_NUMBER() OVER (
		PARTITION BY season, team, xMLBAMID, player, position, fWAR
    ) AS row_num
    FROM fg_batter_data_staging
)
SELECT *
FROM duplicate_batters
WHERE row_num > 1;

WITH duplicate_pitchers AS
(
	SELECT *,
    ROW_NUMBER() OVER (
		PARTITION BY season, team, xMLBAMID, player, fWAR
    ) AS row_num
    FROM fg_batter_data_staging
)
SELECT *
FROM duplicate_pitchers
WHERE row_num > 1;

# There are always 30 MLB teams so let's check if any team changed their abbreviation
# Also checks if any player has an invalid abbreviation
WITH teams AS (
	SELECT DISTINCT(team) AS team
    FROM fg_batter_data_staging
)
SELECT team, ROW_NUMBER() OVER (ORDER BY team) AS row_num
FROM teams;

# The Athletics did, we standardize to OAK since they were mostly OAK from 2021-2025
UPDATE fg_batter_data_staging
SET team = 'OAK'
WHERE team = 'ATH';

UPDATE fg_pitcher_data_staging
SET team = 'OAK'
WHERE team = 'ATH';

# Should only have 'ATH'
# SELECT *
# FROM fg_batter_data_staging
# WHERE team = 'ATH'
# OR    team = 'OAK';
# SELECT *
# FROM fg_pitcher_data_staging
# WHERE team = 'ATH'
# OR    team = 'OAK';

# Check the finalized tables
# SELECT * FROM fg_batter_data_staging LIMIT 10000;
# SELECT * FROM fg_pitcher_data_staging LIMIT 10000;
