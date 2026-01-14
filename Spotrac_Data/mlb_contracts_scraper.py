from typing import List, Optional

import pandas as pd
from bs4 import BeautifulSoup, Comment, Tag

import SpotracSession

session = SpotracSession.SpotracSession()

def team_season_contracts(team: str, season: int) -> pd.DataFrame:
  """
  Meant for testing of how to scrape Spotrac's HTML for MLB contracts
  Takes in the full team name used by Spotrac and one seaason value

  ARGUMENTS:
  team : str : The full hyphenated team name (e.g. chicago-cubs) whose contracts you want
  season : int: The season you want contracts for
  """
  if team is None or season is None:
    raise ValueError(
      "You need to provide a team and season you want contract data for"
    )

  team = str.lower(team)
  contracts_url = 'https://www.spotrac.com/mlb/{}/overview/_/year/{}'.format(team, season)

  response = session.get(contracts_url)
  soup = BeautifulSoup(response.content, 'html.parser')
  table_wrapper = soup.find(id='table-wrapper')
  
  raw_data = []
  tables = []
  headings: Optional[List[str]] = None
  current_header = None

  # We want just the tables and their title headers
  for node in table_wrapper.children:
    if isinstance(node, Comment) and 'SUMMARY' in node:
      break

    if isinstance(node, Tag):
      classes = node['class']
      if 'table-header' in classes:
        current_header = node
      
      elif 'relative' in classes and 'clear' in classes and current_header:
        tables.append((current_header, node))
        current_header = None
  
  # We now want to get all the rows from the tables
  print('Getting the contracts for {}'.format(team))
  for (header, body) in tables:
    h2 = header.find('h2')
    if not h2:
      print("Can't find the header for this table")
      continue

    # Drop the year from the contract category
    full_category = h2.get_text(strip=True)
    category = full_category.split(' ')[1]


    if headings is None:
      headers_row = body.find('thead')
      headings = [th.get_text(strip=True) for th in headers_row.find_all('th')]
    
    rows = body.find('tbody').find_all('tr')
    for row in rows:
      cols = []
      cols.extend([category, team, season])

      # Spotrac stores the names oddly, so we'll remove the first part
      # that duplicates the player's last name
      row_data = []
      for td in row.find_all('td'):
        isFullName = td.find('a')
        if isFullName:
          row_data.append(isFullName.get_text(strip=True))
        else:
          row_data.append(td.text.strip())
      cols.extend(row_data)
      raw_data.append(cols)

  assert headings is not None
  # Change the index column away from an empty string
  headings[0] = 'row'
  headings = ['category', 'team', 'season'] + headings  
  data = pd.DataFrame(data=raw_data, columns=headings)
  data.dropna()

  return data

def season_contracts(season: int) -> pd.DataFrame:
  """
  Retrieves the contracts for every team for a given season

  ARGUMENTS:
  season : int : The desired season to retrieve contracts for
  """
  if season is None:
    raise ValueError('You must provide a season that you want contracts for')
  
  teams_map = {
    'ARI': 'arizona-diamondbacks',
    'ATL': 'atlanta-braves',
    'BAL': 'baltimore-orioles',
    'BOS': 'boston-red-sox',
    'CHC': 'chicago-cubs',
    'CHW': 'chicago-white-sox',
    'CIN': 'cincinnati-reds',
    'CLE': 'cleveland-guardians',
    'COL': 'colorado-rockies',
    'DET': 'detroit-tigers',
    'HOU': 'houston-astros',
    'KCR': 'kansas-city-royals',
    'LAA': 'los-angeles-angels',
    'LAD': 'los-angeles-dodgers',
    'MIA': 'miami-marlins',
    'MIL': 'milwaukee-brewers',
    'MIN': 'minnesota-twins',
    'NYM': 'new-york-mets',
    'NYY': 'new-york-yankees',
    'OAK': 'athletics',
    'PHI': 'philadelphia-phillies',
    'PIT': 'pittsburgh-pirates',
    'SDP': 'san-diego-padres',
    'SEA': 'seattle-mariners',
    'SFG': 'san-francisco-giants',
    'STL': 'st-louis-cardinals',
    'TBR': 'tampa-bay-rays',
    'TEX': 'texas-rangers',
    'TOR': 'toronto-blue-jays',
    'WSN': 'washington-nationals'
  }

  url = 'https://www.spotrac.com/mlb/{}/overview/_/year/{}'
  raw_data = []
  headings: Optional[List[str]] = None
  
  for team_abbrev, team in teams_map.items():
    tables = []
    current_header = None

    contracts_url = url.format(team, season)
    response = session.get(contracts_url)
    soup = BeautifulSoup(response.content, 'html.parser')
    table_wrapper = soup.find(id='table-wrapper')

    for node in table_wrapper.children:
      # Stop iterating when we reach the summary to save time
      if isinstance(node, Comment) and 'SUMMARY' in node:
        break
        
      if isinstance(node, Tag):
        classes = node['class']

        # Spotrac structures their HTML in this manner
        # '<div table-header>': Contains the category of contracts (active, injured, retained)
        # '<div relative clear>': Contains the actual player information
        if 'table-header' in classes:
          current_header = node
        elif 'relative' in classes and 'clear' in classes and current_header:
          tables.append((current_header, node))
          current_header = None
        
    for (header, body) in tables:
      h2 = header.find('h2')
      if not h2:
        print("Can't find the header for this table")
        continue
      
      # Drop the year from the contract category
      full_category = h2.get_text(strip=True)
      category = full_category.split(' ')[1]

      if headings is None:
        headers_row = body.find('thead')
        headings = [th.get_text(strip=True) for th in headers_row.find_all('th')]
      
      rows = body.find('tbody').find_all('tr')
      for row in rows:
        cols = []
        cols.extend([category, team_abbrev, season])

        # Spotrac stores the names oddly, so we'll remove the first part
        # that duplicates the player's last name
        row_data = []
        for td in row.find_all('td'):
          isFullName = td.find('a')
          if isFullName:
            row_data.append(isFullName.get_text(strip=True))
          else:
            row_data.append(td.text.strip())
        cols.extend(row_data)
        raw_data.append(cols)
  
  assert headings is not None
  # Change the index column away from an empty string
  headings[0] = 'row'
  headings = ['category', 'team', 'season'] + headings  
  data = pd.DataFrame(data=raw_data, columns=headings)
  data.dropna()

  return data


def main():
  print(season_contracts(2023))
  
if __name__ == '__main__':
  main()
