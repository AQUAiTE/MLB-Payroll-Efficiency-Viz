SELECT * FROM mlb_contracts;

DROP TABLE IF EXISTS mlb_contracts_staging;
CREATE TABLE mlb_contracts_staging (
	category VARCHAR(50),
    team VARCHAR(3),
    season INT,
    player VARCHAR(50),
    position VARCHAR(5),
    age INT,
    salary DECIMAL(12, 2),
    PRIMARY KEY (team, season, player)
); 

INSERT mlb_contracts_staging
SELECT
	category,
    team,
    season,
    player,
    position,
    age,
    salary
FROM mlb_contracts;

SELECT * FROM mlb_contracts_staging;