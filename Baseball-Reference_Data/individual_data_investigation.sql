# Check the finalized tables
SELECT * FROM fg_pitcher_data_staging LIMIT 10000;   -- 2853 Rows
SELECT * FROM bref_pitcher_data_staging LIMIT 10000; -- 2853 Rows
SELECT * FROM fg_batter_data_staging LIMIT 10000;    -- 2390 Rows
SELECT * FROM bref_batter_data_staging LIMIT 10000;  -- 2383 Rows (Before Fixes) 

# Hold on?
# The batter tables don't return the same number of rows
# Let's investigate by checking the common columns: season, team, MLBAMID, player

# This query shows us 11 players, so there must be some an issue with 4 of the entries
SELECT t1.*
FROM fg_batter_data_staging t1
LEFT JOIN bref_batter_data_staging t2
  ON t1.season   = t2.season
 AND t1.team     = t2.team
 AND t1.MLBAMID  = t2.MLBAMID
 AND t1.player   = t2.player
WHERE t2.MLBAMID IS NULL;

# This query shows us 4 players
# Jiman Choi (twice)
# Albert Almora
# Calvin Mitchell
SELECT t2.*
FROM bref_batter_data_staging t2
LEFT JOIN fg_batter_data_staging t1
  ON t1.season   = t2.season
 AND t1.team     = t2.team
 AND t1.MLBAMID  = t2.MLBAMID
 AND t1.player   = t2.player
WHERE t1.MLBAMID IS NULL;

# If we look again, we see that those same 4 players appear in the first query
# However, their names are formatted differently!
# Jiman Choi <-> Ji Man Choi
# Albert Almora <-> Albert Almora Jr.
# Calvin Mitchell <-> Cal Mitchell
# Referencing MLB.com tells us that the second version is the correct one, so we'll use those
UPDATE bref_batter_data_staging
	SET player = CASE player
    WHEN 'Albert Almora' THEN 'Albert Almora Jr.'
    WHEN 'Jiman Choi' THEN 'Ji Man Choi'
    WHEN 'Calvin Mitchell' THEN 'Cal Mitchell'
    ELSE player
END
WHERE player IN (
	'Albert Almora',
    'Jiman Choi',
    'Calvin Mitchell'
);

# Checking again shows us that we now have just the missing 7 players
SELECT * FROM fg_batter_data_staging LIMIT 10000;    -- 2390 Rows
SELECT * FROM bref_batter_data_staging LIMIT 10000;  -- 2383 Rows 
SELECT t1.*
FROM fg_batter_data_staging t1
LEFT JOIN bref_batter_data_staging t2
  ON t1.season   = t2.season
 AND t1.team     = t2.team
 AND t1.MLBAMID  = t2.MLBAMID
 AND t1.player   = t2.player
WHERE t2.MLBAMID IS NULL;

# Now, just repeat for the pitchers!
SELECT t1.*
FROM fg_pitcher_data_staging t1
LEFT JOIN bref_pitcher_data_staging t2
  ON t1.season   = t2.season
 AND t1.team     = t2.team
 AND t1.MLBAMID  = t2.MLBAMID
 AND t1.player   = t2.player
WHERE t2.MLBAMID IS NULL;

SELECT t2.*
FROM bref_pitcher_data_staging t2
LEFT JOIN fg_pitcher_data_staging t1
  ON t1.season   = t2.season
 AND t1.team     = t2.team
 AND t1.MLBAMID  = t2.MLBAMID
 AND t1.player   = t2.player
WHERE t1.MLBAMID IS NULL;

# The same problem happens again! This is the difference between 7 rows:
# Fangraphs <-> Baseball-Reference
# Ralph Garza Jr. <-> Ralph Garza
# Brent Honeywell (2x) <-> Brent Honeywell Jr. (2x)
# Glenn Otto Jr. (2x) <-> Glenn Otto (2x)
# Jose E. Hernandez <-> Jose Hernandez
# JD Hammer <-> J.D. Hammer
# MLB.com matches the Fangraphs names again, so we'll take those
UPDATE bref_pitcher_data_staging
	SET player = CASE player
    WHEN 'Ralph Garza' THEN 'Ralph Garza Jr.'
    WHEN 'Brent Honeywell Jr.' THEN 'Brent Honeywell'
    WHEN 'Glenn Otto' THEN 'Glenn Otto Jr.'
    WHEN 'Jose Hernandez' THEN 'Jose E. Hernandez'
    WHEN 'J.D. Hammer' THEN 'JD Hammer'
    ELSE player
END
WHERE player IN (
	'Ralph Garza',
	'Brent Honeywell Jr.',
	'Glenn Otto',
	'Jose Hernandez',
	'J.D. Hammer'
);

# After some investigation, I found that the common trait the batters share is they have exactly 100 PAs
# After reviewing my code, I found that the qualifier I used for bref data was > 100 PAs instead of >= 100 PAs
# Fixing it will alleviate this problem, and all we have to do is clean the name format again!
# So while the rest of this file will now be unnecessary since those players will not appear,
# it is a good example of why thoroughly querying your data before use is a good idea!
