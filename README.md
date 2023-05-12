# Case study

Case study for interview in P.F.

## Assignment:

### Environment:
To get started run ``` docker-compose up ``` in root directory.
It will create the PostgresSQL database and start generating the data.
It will create an empty MySQL database.
It will launch the analytics.py script.

### Task:

#### Data Generator for the Task
We have provided a data simulator. The simulator writes 3 records per second into a table in PostgresSQL called devices. The structure of the table is the following:
| Property Name | Data Type | Comment |
| --- | --- | --- |
| device_id | UUID | The unique ID of the device sending the data. |
| temperature | Integer | The temperature measured by the device. |
| location | JSON | Latitude and Longitude of the position of the device. |
| time | integer | The time of the signal as a Unix timestamp. |

#### Task: Data ETL
The data generated above needs to be pulled, transformed and saved into a new database environment. Create an ETL pipeline that does the following:
- Pull the data from PostgresSQL
- Calculate the following data aggregations:
  a. The maximum temperatures measured for every device per hours.
  b. The amount of data points aggregated for every device per hours.
  c. Total distance of device movement for every device per hours.
- Store this aggregated data into the provided MySQL database

* To determine the distance between two locations, you can utilize the following formula or a
relevant python/postgresql package:
* `distance = acos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(lon2 - lon1)) * 6371`
  * (where 6371 represents the radius of the Earth in kilometers).
* For assistance with this task, you may find this link helpful: [GeoPy module](https://geopy.readthedocs.io/en/stable/#module-geopy.distance)
* This ETL should live inside the provided docker container and run by the docker-compose command.

#### Submission Guidelines:
Submit your project (without binaries) along with a screenshot showing successful running in a public git repository. We assume that this task should take 1-2 hours, not more. We will also pay attention to your coding style, so make sure your solution is written in a concise and clear manner. You have 5 days to complete the task and return the link to your git repository. We will check that no commit to the repository was made after the deadline.
If you have any questions about the task, do not hesitate to reach out to us.

Your task will be to write the ETL script inside the analytics/analytics.py file.

## Solution:
This is a very interesting task and I decided to do more than just a simple ETL script.

The whole solution is managed using make commands. There are following targets available in the Makefile:
* `make init` - initializes the environment for airflow
* `make start-all` - starts the whole environment
* `make stop-all` - stops the whole environment
* `make open-psql` - opens psql console to the PostgreSQL database for manual checks of data
* `make show-stats-per-hour` - starts the analytical query in PostgreSQL database to show required results summarized per hour
* `make show-latest-10` - starts query in PostgreSQL database to show latest 10 records for each probe
* `make build-jupyter-image` - builds the image for Jupyter notebook
* `make run-jupyter` - runs the Jupyter notebook
* `make open-mysql` - opens mysql console to the MySQL database for manual checks of data in the target database
* `make build-analytics` - builds the image for the analytics script
* `make run-analytics` - runs the analytics script

### Airflow
* I decided to use Airflow to manage the whole process. Airflow is running in Docker.
* ETL script is implemented as a PythonOperator in Airflow.
* Access Airflow UI on [http://localhost:8080](http://localhost:8080)
  * default login is: airflow / airflow

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
* ETL script in Python is created to load the data from PostgreSQL database to MySQL database.
  * It is committed in the directory `analytics`.
  * It is using Pandas and geopy libraries to process the data.

