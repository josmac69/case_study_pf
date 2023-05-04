from os import environ
from time import sleep
from sqlalchemy import create_engine, inspect
from sqlalchemy.exc import OperationalError
from sqlalchemy import Column, Integer, Float, DateTime, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.sql import func
import pandas as pd
from geopy.distance import great_circle
import uuid

print('Waiting for the data generator...')
#sleep(20)
print('ETL Starting...')

while True:
    try:
        pg_engine = create_engine(environ["POSTGRESQL_CS"], pool_pre_ping=True, pool_size=10)
        break
    except OperationalError:
        sleep(0.1)
print('Connection to PostgresSQL successful.')

while True:
    try:
        mysql_engine = create_engine(environ["MYSQL_CS"], pool_pre_ping=True, pool_size=10)
        break
    except OperationalError:
        sleep(0.1)
print('Connection to MySQL successful.')

# Write the solution here

# Create a session for each database
pg_session = sessionmaker(bind=pg_engine)()
mysql_session = sessionmaker(bind=mysql_engine)()

# Create a declarative base for defining tables in MySQL
Base = declarative_base()

# Define a table for storing aggregated data in MySQL
class AggregatedData(Base):
    __tablename__ = 'aggregated_data'

    id = Column(Integer, primary_key=True)
    device_id = Column(String(50), default=str(uuid.uuid4()), nullable=False)
    hour = Column(DateTime)
    max_temperature = Column(Float)
    data_points = Column(Integer)
    distance = Column(Float)

# Check if the MySQL table exists, create it if it doesn't exist
#if not mysql_engine.dialect.has_table(mysql_engine, 'aggregated_data'):
if not inspect(mysql_engine).has_table('aggregated_data'):
    Base.metadata.create_all(mysql_engine)

# Get the last hour of data that was already stored in MySQL, if any
last_hour = mysql_session.query(func.max(AggregatedData.hour)).scalar()

# Get the data from PostgreSQL including last hour stored in MySQL to make sure it was fully processed
data_query = """SELECT device_id, temperature,
		json_extract_path_text(location::json, 'latitude') as latitude,
		json_extract_path_text(location::json, 'longitude') as longitude,
		json_extract_path_text( (lag(location) over w)::json, 'latitude') as prev_latitude,
		json_extract_path_text( (lag(location) over w)::json, 'longitude') as prev_longitude,
		time FROM devices"""
if last_hour:
    data_query = f"{data_query} WHERE time >= '{last_hour.strftime('%Y-%m-%d %H:%M:%S')}'"

data_query = f"{data_query} WINDOW w AS (PARTITION BY device_id ORDER BY time)"

devices_df = pd.read_sql_query(data_query, pg_engine)

# Convert the 'time' column to a datetime object
devices_df['time'] = pd.to_datetime(devices_df['time'].astype(int), unit='s', origin='unix')

# Set the 'time' column as the index
devices_df.set_index('time', inplace=True)

# Calculate the summary of temperatures, data points, and distances for each device and hour
for device_id, device_group in devices_df.groupby('device_id'):
    for hour, hour_group in device_group.groupby(pd.Grouper(freq='H')):
        # Calculate the maximum temperature and data points for this hour
        max_temperature = hour_group['temperature'].max()
        data_points = hour_group['temperature'].count()

        # Calculate the distance traveled for this hour
        distances = hour_group.apply(
            lambda row: great_circle(
                (row['latitude'], row['longitude']),
                (row['prev_latitude'], row['prev_longitude'])
            ).meters if pd.notnull(row['prev_latitude']) else 0,
            axis=1
        )
        distance_sum = distances.sum()

        # Create a new AggregatedData object for this hour's data
        aggregated_data = AggregatedData(
            device_id=device_id,
            hour=hour,
            max_temperature=max_temperature,
            data_points=data_points,
            distance=distance_sum
        )

        # Add the new data to the MySQL table
        mysql_session.merge(aggregated_data)

# Commit the changes to the MySQL database
mysql_session.commit()

# Close the database sessions
pg_session.close()
mysql_session.close()
