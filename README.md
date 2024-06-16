 
# Solution for Indicium Tech Code Challenge 06/2024

Challenge statement: [https://github.com/techindicium/code-challenge](https://github.com/techindicium/code-challenge)
Solution author: Pedro Silva dos Santos
  

## Table of contents
1. [Requirements](#requirements)
2. [How to run](#how-to-run)
3.  Airflow scheduling
4. Results
5. Implemention Details.


## Requirements 
It is assumed that you have Docker installed
Meltano's Airflow plugin requires Python 3.9, see: [https://hub.meltano.com/orchestrators/airflow/](https://hub.meltano.com/orchestrators/airflow/) 

> The version of Airflow currently installed with Meltano (2.1.2)
> requires that Python be at version 3.9 or lower.

Make sure your shell is running Python 3.9 (with  `python3 --version`).
If not, setup  a virtual environment with `pyenv`:

Install [`pyenv`](https://github.com/pyenv/pyenv-installer):
```
curl https://pyenv.run | bash
```
Install Python 3.9:
```
pyenv install 3.9
```



Set a directory-specific Python version and restart your shell: 
```
pyenv local 3.9
exec "$SHELL"
python3 --version
```

 ## How to run 
  Install meltano:
 

    pip install meltano

  
Build the project:

    bash ./build.sh

Run full pipeline:

    bash ./init.sh
    
That's it. Verify if everything went well by checking `queries/` folder.
Alternatively, (re)run the pipeline for a specific date by passing an argument with a day from the past (ISO format):

    bash ./init.sh 2024-06-16

### Running each job individually
Challenge's step 1:

    meltano run details-to-csv
    meltano run postgres-to-csv
    
Challenge's step 2:

    meltano run disk-to-postgres

Notice as you cannot pass a date argument, these runs will use the ARG_DATE  date set in `.env` file.

## Airflow scheduling

Airflow scheduler should be already running in the background, you can make sure by running:

    meltano invoke airflow scheduler

### Use these commands to verify if Airflow scheduling is setup correctly:

Show all dags:

    meltano invoke airflow dags list

Check the next 10 exection times for each dag:

    meltano invoke airflow dags next-execution -n 10 meltano_load-details-csv_details-to-csv
    meltano invoke airflow dags next-execution -n 10 meltano_load-postgres-csv_postgres-to-csv 
    meltano invoke airflow dags next-execution -n 10 meltano_load-disk-postgres_disk-to-postgres

The last dag is scheduled arbitrarily for 5 minutes after the first two, because the results from those are needed for it.

> Dags are generated automatically by Meltano because of the "`schedules:`" entries in `Meltano.yml`. Meltano uses `orchestrate/airflow/dags/meltano_dag_generator.py` to do so.

## Results

### Step 1
For the challenge's first step, where data is written to local disk, this is the folder structure:
<pre>
    /data/postgres/{table}/2024-01-02/<b>{table}.csv</b>
    /data/postgres/{table}/2024-01-02/<b>{table}.csv</b>
    /data/csv/2024-01-02/<b>order_details.csv</b>
    </pre>
CSV format was chosen because it's convenient for data analysis usage:

 - Easily readable through spreadsheet applications (Microsoft Excel, Google Docs),
- Easy importing to BI tools,
- Low storage usage (no formatting or metadata and compressible),
- Easy to write custom data processing scripts.

The jobs run were:

    meltano run details-to-csv 
    meltano run postgres-to-csv

Notice they have a Python script (`organiza_csv:run_details`) to create the paths
Meltano.yml
```
jobs:
- name: details-to-csv
  tasks:
  - tap-csv-details target-csv-details organiza_csv:run_details
...
```


### Step 2
For the second step, data is loaded from the local filesystem (from step 1) to the final database (named targetdb).
The job run was:

    meltano run disk-to-postgres

Notice they also have Python script (`organiza_csv:run_tables`) to create the paths:
Meltano.yml
```
jobs:
- name: postgres-to-csv
  tasks:
  - tap-postgres handle-real-dt target-csv-tables organiza_csv:run_tables
...
```

The final database now has all necessary tables to run the final goal query that shows the orders and its details. Final goal query is located at `queries/final_goal.sql` and its results are at `queries/{ISO_date}/final_goal.csv`. Notice there are other sample queries beside it.


## Implementation details

### CSV delimiter escaping
Some files have commas in their content, instead of escaping them it was decided to change the delimiters to semicolons.

### Configuration of `tap-postgres` and `target-csv-tables`

This loader and this extractor are used in step 1 to load `northwind` database to disk.

The extractor only retrieves the public schema, using `select: - public-*.*`, to avoid `information-schema` (because of this issue https://github.com/MeltanoLabs/tap-postgres/issues/437). No side effects by doing this as `information-schema` is metadata.
File `Meltano.yml:`
```
plugins:
  extractors:
  ...
  - name: tap-postgres
    ...
    select:
    - public-*.*
```

There are empty tables in `northwind` (namely `customer_customer_demo` and `customer_demographics`), after extracted the loader does not create files in the disk, as they would be empty. Creating them anyway could be a good practice, depending on the application. For this challenge, they are not being created. 


### I needed to make sure `Real` data type is handled. 

This data type occurs in `orders.freight` and `products.unit_price` (in `northwind` database), but `Real` is not supported by `target-csv`. To handle this, `meltano-map-transformer` mapper was set up to map `public-orders.freight` and `public-products.unit_price` to `float` type:
```
    mappers:
      - name: meltano-map-transformer
        variant: meltano
        pip_url: git+https://github.com/MeltanoLabs/meltano-map-transform.git
        executable: meltano-map-transform
        mappings:
        - name: handle-real-dt
          config:
            stream_maps:
              public-orders:
                freight: float(freight)
              public-products:
                unit_price: float(unit_price)
```

> `bpchar` data type is also not reconized, but the tap falls back to
> string and everything goes well.	

### Configuration of `tap-csv-all`
 
 This tap is used in setp 2 and extracs all `.csv` files from local disk and prepares them to be sent to the target database.
See part of the config file:

    config:
          files:
          - entity: order_details
            path: data/csv/$ARG_DATE/order_details.csv
            delimiter: ;
            keys:
            - order_id
            - product_id
The composite primary key is set correctly to avoid problems after loading them into the database. Setting this incorreclty could cause data loss and/or corruption.
It is necessary to create config entries for each file. For this challenge they were made manually, but it would be convenient to write a script to search for them and create the config entries automatically, especially for bigger databases.

### Loading into target database
No data type handling is made when loading into target database from `.csv` files, and all columns are created as `varchar`. This could cause problems for data integrity.

### To-dos

It would be good to implement exception handling, some way of generating better logs and to put Python and Meltano inside a container.
