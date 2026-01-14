import os
from dotenv import load_dotenv

import mysql.connector as connector
import pandas as pd

load_dotenv()

mlb_standings = pd.read_csv('mlb_standings_2021_2025.csv')
team_batting = pd.read_csv('team_batting_2021_2025.csv')
team_pitching = pd.read_csv('team_pitching_2021_2025.csv')
bwar_pitcher_data = pd.read_csv('bwar_pitching_data.csv')
bwar_batting_data = pd.read_csv('bwar_batting_data.csv')


def insert_data(df: pd.DataFrame, table: str, primary_keys: list, conn, cursor):
  columns = ', '.join([f'`{col}`' for col in df.columns])
  values = ', '.join(['%s'] * len(df.columns))
  update_condition = ', '.join([f'`{col}`=VALUES(`{col}`)' for col in df.columns if col not in primary_keys])
  insert_query = f'INSERT INTO {table} ({columns}) VALUES ({values}) ON DUPLICATE KEY UPDATE {update_condition}'

  cursor.executemany(insert_query, df.values.tolist())
  conn.commit()
  print(f'Inserted {len(df)} rows into {table}')

try:
  conn = connector.connect(
    database = os.getenv('MYSQL_DB'),
    host=os.getenv('MYSQL_HOST'),
    port=os.getenv('MYSQL_PORT'),
    user=os.getenv('MYSQL_USER'),
    password=os.getenv('MYSQL_PASS')
  )

  if conn.is_connected():
    print('Successful connection')
    cursor = conn.cursor()

    # Insert the standings and team batting data
    insert_data(mlb_standings, 'mlb_team_win_loss', primary_keys=['Tm', 'season'], conn=conn, cursor=cursor)
    insert_data(team_batting, 'bref_team_batting', primary_keys=['season', 'team_abbrev'], conn=conn, cursor=cursor)
    insert_data(team_pitching, 'bref_team_pitching', primary_keys=['season', 'team_abbrev'], conn=conn, cursor=cursor)
    insert_data(bwar_pitcher_data, 'bref_pitcher_data', primary_keys=['mlb_ID', 'year_ID', 'team_ID'], conn=conn, cursor=cursor)
    insert_data(bwar_batting_data, 'bref_batter_data', primary_keys=['mlb_ID', 'year_ID', 'team_ID'], conn=conn, cursor=cursor)


except connector.Error as e:
  print(f'Error with MySQL connection: {e}')

finally:
  if conn.is_connected():
    cursor.close()
    conn.close()
    print('Connection and cursor closed')