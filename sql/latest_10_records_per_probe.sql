with srcdata as (
    select * from (
        select device_id,
        temperature,
        location,
        json_extract_path_text(location::json, 'latitude') as latitude,
        json_extract_path_text(location::json, 'longitude') as longitude,
        lag(location) over w as prev_location,
        json_extract_path_text( (lag(location) over w)::json, 'latitude') as prev_latitude,
        json_extract_path_text( (lag(location) over w)::json, 'longitude') as prev_longitude,
        time,
        row_number() over (partition by device_id order by time desc) as rownum
        from public.devices
        window w as (partition by device_id order by time)
    ) a )
select
    device_id,
    time,
    location,
    prev_location,
    ( acos(sin(latitude::float) * sin(prev_latitude::float) +
    cos(latitude::float) * cos(prev_latitude::float) *
    cos(prev_longitude::float - longitude::float)) * 6371 )
    AS distance_from_previous
from srcdata
where
    rownum <= 10
order by
    device_id,
    time desc;
