library(baseballr)
library(dplyr)
batter_data <- fg_batter_leaders(
  startseason = "2025",
  endseason = "2025",
  qual = "0",
  pageitems = "2000"
)

team_data <- batter_data %>%
    filter(team_name == "ATH")

print(team_data, n = 100)
