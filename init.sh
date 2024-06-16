#!/bin/bash

# ARG_DATE will be used by tap-csv-all to find the path
# respective to the date to the .csv files


# Check if ARG_DATE is already defined in .env
if grep -q "^ARG_DATE=" .env; then
  if [[ -z $1 ]]; then
    # Set ARG_DATE to current date if no argument is provided
    sed -i "s,^ARG_DATE=.*,ARG_DATE=$(date +%F)," .env
  else
    # Set ARG_DATE to the provided argument
    sed -i "s,^ARG_DATE=.*,ARG_DATE=${1}," .env
  fi
else
  # ARG_DATE not found in .env, create it
  if [[ -z $1 ]]; then
    echo "ARG_DATE=$TODAY" >> .env
  else
    echo "ARG_DATE=${1}" >> .env
  fi
fi

# Print the updated .env file
cat .env


#meltano invoke airflow dags trigger meltano_load-details-csv_details-to-csv
#meltano invoke airflow dags trigger meltano_load-postgres-csv_postgres-to-csv
#meltano invoke airflow dags trigger meltano_load-disk-postgres_disk-to-postgres

echo 'Extracting order_details.csv from csv to disk.'
meltano run details-to-csv

echo 'Extracting from northwind databse to disk.'
meltano run postgres-to-csv

echo 'Extracting all .csv from disk to targetdb'
meltano run disk-to-postgres


# Execute queries
source .env # to get the date (ARG_DATE)

# Ensure the directory for current date exists
output_dir="queries/$ARG_DATE"
if [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
fi

# run fix_datatype.sql first
# converts some varchar columns to float
# for the queries
docker exec -i challenge-db2-1 sh -c "
  psql -U targetdb_user -d targetdb -A -F ';' " < queries/fix_datatype.sql


# Loop through each SQL file in the queries directory
for sql_file in queries/*.sql; do
    # Extract file name without extension
    # The same name will be used for the CSV
    base_name=$(basename "$sql_file" .sql)

    # Execute psql and redirect output to CSV
    docker exec -i challenge-db2-1 sh -c "
     psql -U targetdb_user -d targetdb -A -F ';' " < $sql_file > "queries/$ARG_DATE/${base_name}.csv"
    
    echo "Executed $sql_file and saved output to queries/$ARG_DATE/${base_name}.csv"
done


echo "SQL query executed and results saved to queries folder"