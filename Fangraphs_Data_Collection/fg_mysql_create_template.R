library(DBI)
library(RMariaDB)

# Only data frames can be written as tables with dbWriteTable
combined_batter_data_df <- as.data.frame(combined_batter_data)
combined_pitcher_data_df <- as.data.frame(combined_pitcher_data)

# Connect to the MySQL database
# WARNING: This was a local only project so it's okay in this case but typically
# NEVER directly use a password when connecting to a DB
# Usually, you want to use a config or env var
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
