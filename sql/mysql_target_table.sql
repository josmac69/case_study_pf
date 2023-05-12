CREATE TABLE IF NOT EXISTS probe_aggregates (
    device_id UUID,
    time_interval_end TIMESTAMP,
    min_temperature FLOAT,
    max_temperature FLOAT,
    avg_temperature FLOAT,
    min_pressure FLOAT,
    max_pressure FLOAT,
    avg_pressure FLOAT,
    min_height FLOAT,
    max_height FLOAT,
    avg_height FLOAT,
    min_wind_speed FLOAT,
    max_wind_speed FLOAT,
    avg_wind_speed FLOAT,
    distance_travelled FLOAT,
    data_gaps INT,
    has_gap BOOLEAN
);
