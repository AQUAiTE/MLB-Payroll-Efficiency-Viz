library(baseballr)
library(dplyr)
batter_data <- fg_batter_leaders(
  startseason = "2025",
  endseason = "2025",
  qual = "0",
  pageitems = "2000"
)

head(batter_data)
str(batter_data)

batter_data_key_info <- batter_data %>%
  select(Season, team_name, xMLBAMID, PlayerName, position, WAR)

print(batter_data_key_info, n = 100)
