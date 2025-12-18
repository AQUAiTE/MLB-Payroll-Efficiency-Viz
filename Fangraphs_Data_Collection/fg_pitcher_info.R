library(baseballr)
library(dplyr)

all_pitcher_data <- list()

# Purpose: Retrieve the needed pitcher information from 2021-2025 for every team
# Info Retrieved: Season, team_name, xMLBAMID, PlayerName, WAR
# Notice: Retrieves all pitchers (both qualified or unqualified)
# Notice: The record for most players used by a single team in a season is 70
for (year in 2021:2025) {
  for (team in 1:30) {
    pitcher_info <- fg_pitcher_leaders(
      startseason = year,
      endseason = year,
      qual = "0",
      team = team,
      pageitems = "100"
    )
    
    filtered_pitcher_info <- pitcher_info %>%
      select(Season, team_name, xMLBAMID, PlayerName, WAR)
    
    all_pitcher_data[[paste(year, team, sep = "_")]] <- filtered_pitcher_info
  }
}

combined_pitcher_data <- bind_rows(all_pitcher_data)