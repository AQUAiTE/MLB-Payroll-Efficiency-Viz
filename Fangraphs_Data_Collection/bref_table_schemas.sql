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
    PRIMARY KEY (Tm, season)
)
