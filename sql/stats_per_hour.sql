with srcdata as (
    select device_id,
    temperature,
    json_extract_path_text(location::json, 'latitude') as latitude,
    json_extract_path_text(location::json, 'longitude') as longitude,
    json_extract_path_text( (lag(location) over w)::json, 'latitude') as prev_latitude,
    json_extract_path_text( (lag(location) over w)::json, 'longitude') as prev_longitude,
    time,
    date_trunc('hour', to_timestamp(time::bigint)) as date_hour,
    date_trunc('minute', to_timestamp(time::bigint)) as date_1min
    from public.devices
    window w as (partition by device_id order by time) ),
calcdist as (
    select device_id,
    time,
    date_hour,
    date_1min,
    temperature,
    ( acos(sin(latitude::float) * sin(prev_latitude::float) +
    cos(latitude::float) * cos(prev_latitude::float) *
    cos(prev_longitude::float - longitude::float)) * 6371 )
    AS distance_from_previous_km
    from srcdata )
select
    device_id,
    date_hour,
    min(temperature) as min_temperature,
    max(temperature) as max_temperature,
    round(sum(distance_from_previous_km)::numeric,2) as total_distance_km,
    count(*) as datapointscount
from calcdist
group by
    device_id,
    date_hour
order by
    device_id,
    date_hour;