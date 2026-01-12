# Working on the standings table
DROP TABLE IF EXISTS mlb_standings_combined;

CREATE TABLE mlb_standings_combined LIKE mlb_team_win_loss;

INSERT mlb_standings_combined
SELECT *
FROM mlb_team_win_loss;

# We want to have the league and division placement in our standings
ALTER TABLE mlb_standings_combined
	RENAME COLUMN Tm TO team,
    RENAME COLUMN W to wins,
    RENAME COLUMN L to losses,
    RENAME COLUMN `W-L%` TO win_pct,
    RENAME COLUMN GB to gb,
	ADD COLUMN league VARCHAR(2),
    ADD COLUMN divisional_placement BIGINT;

UPDATE mlb_standings_combined
SET team = 'Oakland Athletics'
WHERE team = 'Athletics';
    
# We want to make sure we know the difference between AL West and NL West
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

# We want a team's place in their division to be part of the visualization, so add that column
UPDATE mlb_standings_combined standings
JOIN (
	SELECT *,
    ROW_NUMBER() OVER (
		PARTITION BY season, league, division
        ORDER BY gb
    ) AS division_placement
	FROM mlb_standings_combined
) AS division_standings
ON standings.team = division_standings.team
	AND standings.season = division_standings.season
SET standings.divisional_placement = division_standings.division_placement;

SELECT * FROM mlb_standings_combined ORDER BY season, division, league, gb;