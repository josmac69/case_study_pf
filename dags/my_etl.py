from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2021, 1, 1),
    'email': ['airflow@example.com'],
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'probe_aggregates', default_args=default_args, schedule_interval=timedelta(minutes=10))

def calculate_aggregates_10min():
    # Connect to PostgreSQL and MySQL using credentials from secrets
    # Fetch data for the last 10 minutes
    # Calculate aggregates and distance travelled
    # Insert results into MySQL

def calculate_aggregates_1hour():
    # Connect to PostgreSQL and MySQL using credentials from secrets
    # Fetch data for the last hour
    # Calculate aggregates and distance travelled
    # Insert results into MySQL

t1 = PythonOperator(
    task_id='calculate_aggregates_10min',
    python_callable=calculate_aggregates_10min,
    dag=dag)

t2 = PythonOperator(
    task_id='calculate_aggregates_1hour',
    python_callable=calculate_aggregates_1hour,
    dag=dag)
