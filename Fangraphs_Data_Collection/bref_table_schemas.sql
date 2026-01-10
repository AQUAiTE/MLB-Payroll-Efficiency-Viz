DROP TABLE IF EXISTS bref_team_batting;
CREATE TABLE IF NOT EXISTS bref_team_batting (
	season INT,
    team_abbrev VARCHAR(3),
    team_name VARCHAR(50),
    runs_per_game DECIMAL(4, 2),
    onbase_plus_slugging DECIMAL(4, 3),
    onbase_plus_slugging_plus DECIMAL(3, 0),
    PRIMARY KEY (season, team_abbrev)
);

DROP TABLE IF EXISTS mlb_team_win_loss;
CREATE TABLE IF NOT EXISTS mlb_team_win_loss (
	Tm VARCHAR(50),
    W INT,
    L INT,
    `W-L%` DECIMAL(4, 3),
    GB DECIMAL(3, 1),
    season INT,
    division VARCHAR(10),
    PRIMARY KEY (Tm, season)
);

DROP TABLE IF EXISTS bref_pitcher_data;
CREATE TABLE IF NOT EXISTS bref_pitcher_data (
	name_common VARCHAR(50),
    mlb_ID INT,
    year_ID INT,
    team_ID VARCHAR(3),
    lg_ID VARCHAR(2),
    WAR DECIMAL(4, 1),
    PRIMARY KEY (mlb_ID, year_ID, team_ID)
);

DROP TABLE IF EXISTS bref_batter_data;
CREATE TABLE IF NOT EXISTS bref_batter_data (
	name_common VARCHAR(50),
    mlb_ID INT,
    year_ID INT,
    team_ID VARCHAR(3),
    lg_ID VARCHAR(2),
    WAR DECIMAL(4, 1),
    PRIMARY KEY (mlb_ID, year_ID, team_ID)
);
