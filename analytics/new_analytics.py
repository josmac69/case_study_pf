from os import environ
from time import sleep
from sqlalchemy import create_engine, inspect, Column, Integer, Float, DateTime, String, func
from sqlalchemy.exc import OperationalError
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import pandas as pd
from geopy.distance import great_circle
import uuid


class AggregatedData(declarative_base()):
    __tablename__ = 'aggregated_data'

    id = Column(Integer, primary_key=True)
    device_id = Column(String(50), default=str(uuid.uuid4()), nullable=False)
    hour = Column(DateTime)
    max_temperature = Column(Float)
    data_points = Column(Integer)
    distance = Column(Float)


class DatabaseManager:
    def __init__(self, db_url):
        self.db_url = db_url
        self.engine = None
        self.session = None

    def connect_to_database(self):
        while True:
            try:
                self.engine = create_engine(self.db_url, pool_pre_ping=True, pool_size=10)
                break
            except OperationalError:
                sleep(0.1)
        print(f'Connection to {self.db_url} successful.')
        self.session = sessionmaker(bind=self.engine)()

    def create_aggregated_data_table(self):
        if not inspect(self.engine).has_table('aggregated_data'):
            AggregatedData.metadata.create_all(self.engine)

    def get_last_hour(self):
        return self.session.query(func.max(AggregatedData.hour)).scalar()

    def add_aggregated_data(self, data):
        self.session.merge(data)

    def commit_changes(self):
        self.session.commit()

    def close_connection(self):
        self.session.close()


def get_devices_data(engine, last_hour=None):
    data_query = """
        SELECT device_id, temperature,
        json_extract_path_text(location::json, 'latitude') as latitude,
        json_extract_path_text(location::json, 'longitude') as longitude,
        json_extract_path_text( (lag(location) over w)::json, 'latitude') as prev_latitude,
        json_extract_path_text( (lag(location) over w)::json, 'longitude') as prev_longitude,
        time FROM devices
    """
    if last_hour:
        data_query = f"{data_query} WHERE time >= '{last_hour.strftime('%Y-%m-%d %H:%M:%S')}'"
    data_query = f"{data_query} WINDOW w AS (PARTITION BY device_id ORDER BY time)"

    devices_df = pd.read_sql_query(data_query, engine)
    devices_df['time'] = pd.to_datetime(devices_df['time'].astype(int), unit='s', origin='unix')
    devices_df.set_index('time', inplace=True)

    return devices_df


def calculate_aggregated_data(devices_df):
    result = []
    for device_id, device_group in devices_df.groupby('device_id'):
        for hour, hour_group in device_group.groupby(pd.Grouper(freq='H')):
            max_temperature = hour_group['temperature'].max()
            data_points = hour_group['temperature'].count()

            distances = hour_group.apply(
                lambda row: great_circle(
                    (row['latitude'], row['longitude']),
                    (row['prev_latitude'], row['prev_longitude'])
                ).meters if pd.notnull(row['prev_latitude']) else 0,
                axis=1
            )
            distance_sum = distances.sum()

            aggregated_data = AggregatedData(
                device_id=device_id,
                hour=hour,
                max_temperature=max_temperature,
                data_points=data_points,
                distance=distance_sum
            )

            result.append(aggregated_data)
    return result

def main():
    print('Waiting for the data generator...')
    sleep(20)
    print('ETL Starting...')

    pg_manager = DatabaseManager(environ["POSTGRESQL_CS"])
    pg_manager.connect_to_database()

    mysql_manager = DatabaseManager(environ["MYSQL_CS"])
    mysql_manager.connect_to_database()

    mysql_manager.create_aggregated_data_table()

    last_hour = mysql_manager.get_last_hour()

    devices_df = get_devices_data(pg_manager.engine, last_hour)

    aggregated_data = calculate_aggregated_data(devices_df)

    for data in aggregated_data:
        mysql_manager.add_aggregated_data(data)

    mysql_manager.commit_changes()

    pg_manager.close_connection()
    mysql_manager.close_connection()


if __name__ == '__main__':
    main()
