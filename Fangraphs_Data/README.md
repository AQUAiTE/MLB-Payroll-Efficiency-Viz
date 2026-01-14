# Pulling Fangraphs Data w/ Baseballr

## Intro
This is my first ever attempt at a real visualization project where I have to pull data from multiple sources. The first source I had to tackle was [FanGraphs](https://www.fangraphs.com/), which provides plenty of different analytics for following the MLB. Luckily, I found that the great Bill Petti had already done the hard work of generating scrapers for various MLB websites through his R package [`baseballr`](https://billpetti.github.io/baseballr/).

So rather than having to walk you through the process of setting up scrapers, instead I get to go over my bumpy road as I used R for the first time since a random math class in college.

## Why?
The main reason I wanted to get FanGraphs data was that the basis of this project is that I wanted to see the relative efficiency of MLB teams' payrolls on various levels. One of these ways is fWAR (**F**anGraphs **W**ins **A**bove **R**eplacement), which is FanGraphs' version of the stat that I defined in my main outline.

While any WAR stat is not the be-all and end-all for how well a team spent their money, it is a significant stat that does measure production very well. While a team full of positive WAR players can still lose, it doesn't mean that the team did not spend their payroll in a positive manner.

## How?
The main libraries I used were `dplyr` and `baseballr`. FanGraphs stores leaderboards for both pitchers and batters, which I made a script for each. However, the script is essentially the same for each, seen below:
```
library(baseballr)
library(dplyr)

all_batter_data <- list()

for (year in 2021:2025) {
  for (team in 1:30) {
    [P/B]_info <- fg_[P/B]_leaders(
      startseason = year,
      endseason = year,
      qual = "0",
      team = team,
      pageitems = "100"
    )
    
    filtered_[P/B]_info <- [P/B]_info %>%
      select(Season, team_name, xMLBAMID, PlayerName, WAR)
    
    all_[P/B]_data[[paste(year, team, sep = "_")]] <- filtered_[P/B]_info
  }
}

combined_[P/B]_data <- bind_rows(all_[P/B]_data)
```
This script goes through each year and team from 2021-2025, pulling each team's batters for that year. I grab the sufficient information needed, and then place it in a list of objects to be binded at the end. 

For this, note that [] represents text that I either filled in with pitcher (P) or batter (B). The batter version of this script also included an extra argument `pos = np`, and an extra selected column `position`. That argument excludes pitchers, which I believed made sense as MLB teams simply do not consider the batting abilities when signing pitchers, and the MLB [hasn't forced pitchers to hit since 2022](https://www.mlb.com/glossary/rules/designated-hitter-rule). The extra column is needed as while all pitchers are listed as "P", every batter has a different position (C/1B/2B/3B/SS/OF).

The arbitrary number 100 for `pageitems` is chosen due to the fact that no MLB team has ever used [more than 71 players in a single season](https://www.si.com/mlb/braves/onsi/news/atlanta-braves-mlb-record-charlie-morton-appearance).

## Next Steps
The other script I used so far for the FanGraphs data is below:
```
library(DBI)
library(RMariaDB)

combined_batter_data_df <- as.data.frame(combined_batter_data)
combined_pitcher_data_df <- as.data.frame(combined_pitcher_data)

con <- dbConnect(
  RMariaDB::MariaDB(),
  dbname = "mlb_salary_efficiency_data",
  user = #MySQL User,
  password = #MySQL Password
  host = #MySQL Host
  port = #MySQL Connection Port
)

dbWriteTable(con, "fg_batter_data", combined_batter_data_df)
dbWriteTable(con, "fg_pitcher_data", combined_pitcher_data_df)

dbDisconnect(con)
```
I highly recommend not ever directly using a password, but since this is historical data that doesn't require updates, it was fine for a local transfer to a MySQL database.

With the data loaded into MySQL, it will wait for me to finish gathering all the data I need from other sources. In the meantime, I do need to perform a couple of steps to finish up this data aside from the usual cleaning:
* The (formerly Oakland) Athletics have their players from 2021-2025 under two abbreviations: "OAK" and "ATH". I must consolidate these to be one, and while my heart says "OAK", the present abbreviation is "ATH".
* Players who were traded midseason were originally returned as having the team "---". While I solved this by iterating through each team, I must still verify that no player is missing a team abbreviation.
