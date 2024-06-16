import os
import shutil
import re
from datetime import datetime

def load_env_file(file_path):
    with open(file_path) as f:
        for line in f:
            # Remove comments and empty lines
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            # Split the line into key and value
            key, value = line.split('=', 1)

            # Remove any surrounding quotes
            value = value.strip('\'"')

            # Set the environment variable
            os.environ[key] = value


def extract_table_and_date(file_name): 
    # Define the regex pattern to match the filename
    pattern = r'(?P<table_name>[a-zA-Z0-9_]+)-(?P<timestamp>\d{8}T\d{6})\.csv'

    # Match the pattern with the filename
    match = re.match(pattern, file_name)
    
    if match:
        # Extract table name
        table_name = match.group('table_name')
        
        return table_name
    else:
        raise ValueError("Filename does not match the expected pattern")




# Load the .env file
load_env_file('.env')

arg_date = os.getenv('ARG_DATE')

os.chmod('./data/csv', 0o777)
source_dir = './data/csv'
target_base_dir = './data/csv'

for file_name in os.listdir(source_dir):
    if file_name.endswith('.csv'):
        table_name = extract_table_and_date(file_name)
        target_dir = os.path.join(target_base_dir,arg_date)
        os.makedirs(target_dir, exist_ok=True)

        # moves file to target_dir and removes date and timestamp from file name
        shutil.move(os.path.join(source_dir, file_name), os.path.join(target_dir, table_name+'.csv')) 