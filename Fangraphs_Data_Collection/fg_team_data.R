library(baseballr)
library(dplyr)

all_team_batting <- list()
all_team_pitching <- list()

# Purpose: Retrieve the team batting stats for each team per-season
# Info Retrieved: Season, team_name, xMLBAMID, PlayerName, position, WAR
for (year in 2021:2025) {
  team_batting <- fg_team_batter(
    startseason = year,
    endseason = year,
  )
  
  team_pitching <- fg_team_pitcher(
    startseason = year,
    endseason = year
  )
  
  filtered_team_info <- team_batting %>%
    select(Season, team_name, wRC_plus)
  all_team_batting[[paste(year)]] <- filtered_team_info
  
  filtered_team_info <- team_pitching %>%
    select(Season, team_name, FIP, 'ERA-')
  all_team_pitching[[paste(year)]] <- filtered_team_info
}

combined_team_batting <- bind_rows(all_team_batting)
combined_team_pitching <- bind_rows(all_team_pitching)