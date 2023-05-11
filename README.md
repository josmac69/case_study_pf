# Case study

Case study for interview in P.F.

## Assignment:

### Environment:
To get started run ``` docker-compose up ``` in root directory.
It will create the PostgresSQL database and start generating the data.
It will create an empty MySQL database.
It will launch the analytics.py script.

### Task:
Your task will be to write the ETL script inside the analytics/analytics.py file.

## Solution:
This is a very interesting task and I decided to do more than just a simple ETL script.

The whole solution is managed using make commands. There are following targets available in the Makefile:
* `make start-production` - starts the whole environment
* `make stop-all` - stops the whole environment
* `make open-psql` - opens psql console to the PostgreSQL database for manual checks of data
* `make show-stats-per-hour` - starts the analytical query in PostgreSQL database to show required results summarized per hour
* `make show-latest-10` - starts query in PostgreSQL database to show latest 10 records for each probe
* `make build-jupyter-image` - builds the image for Jupyter notebook
* `make run-jupyter` - runs the Jupyter notebook
* `make open-mysql` - opens mysql console to the MySQL database for manual checks of data in the target database
* `make build-analytics` - builds the image for the analytics script
* `make run-analytics` - runs the analytics script

### Analysis of data for the task
* I created a Jupiter notebook to explore and better understand the data.
  * Notebook is committed in the directory `jupyter/notebooks` and its content shows results of the analysis for testing run.
  * Content or the file and results can be checked directly in GitHub. It is able to render the notebook in the browser.
  * Analysis of the data is done using Pandas library.

* PostgreSQL analytical queries
  * I created queries to check data and to show the results required by the task.
  * SQL queries are committed in the directory `sql`.
    * file `sql/latest_10_records_per_probe.sql` contains query to show latest 10 records for each probe
    * file `sql/stats_per_hour.sql` contains query to show required results summarized per hour

### ETL script
* I created the ETL script in Python.
  * It is committed in the directory `analytics`.
  * It is using Pandas library to process the data.

