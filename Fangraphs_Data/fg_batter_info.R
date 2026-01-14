library(baseballr)
library(dplyr)

all_batter_data <- list()

# Purpose: Retrieve the needed player information from 2021-2025 for every team
# Info Retrieved: Season, team_name, xMLBAMID, PlayerName, position, WAR
# Notice: Retrieves batters with >= 100 Plate Appearances
# Notice: The record for most players used by a single team in a season is 70
# so we can limit the pageitems to 100
for (year in 2021:2025) {
  for (team in 1:30) {
    batter_info <- fg_batter_leaders(
      startseason = year,
      endseason = year,
      qual = "100",
      team = team,
      pos = "np",
      pageitems = "100"
    )
    
    filtered_batter_info <- batter_info %>%
      select(Season, team_name, xMLBAMID, PlayerName, position, WAR)
    
    all_batter_data[[paste(year, team, sep = "_")]] <- filtered_batter_info
  }
}

combined_batter_data <- bind_rows(all_batter_data)