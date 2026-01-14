library(DBI)
library(RMariaDB)

# Only data frames can be written as tables with dbWriteTable
combined_batter_data_df <- as.data.frame(combined_batter_data)
combined_pitcher_data_df <- as.data.frame(combined_pitcher_data)
combined_team_batting_df <- as.data.frame(combined_team_batting)
combined_team_pitching_df <- as.data.frame(combined_team_pitching)

# Connect to the MySQL database
# Adjusted to use .Renviron for better security
con <- dbConnect(
  RMariaDB::MariaDB(),
  dbname = Sys.getenv("MYSQL_DB"),
  user = Sys.getenv("MYSQL_USER"),
  password = Sys.getenv("MYSQL_PASS"),
  host = Sys.getenv("MYSQL_HOST"),
  port = Sys.getenv("MYSQL_PORT")
)

dbWriteTable(con, "fg_batter_data", combined_batter_data_df, overwrite=TRUE)
dbWriteTable(con, "fg_pitcher_data", combined_pitcher_data_df, overwrite=TRUE)
dbWriteTable(con, "fg_team_batting", combined_team_batting_df, overwrite=TRUE)
dbWriteTable(con, "fg_team_pitching", combined_team_pitching_df, overwrite=TRUE)

dbDisconnect(con)
