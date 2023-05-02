.PHONY: start-production open-psql show-statistics show-latest-10

start-production:
	docker compose up --build

open-psql:
	docker exec -it psql-container psql -U postgres -d main

show-statistics:
	docker exec -it psql-container \
	psql -U postgres -d main \
	-c "select device_id, min(temperature) as mintemp, max(temperature) as maxtemp, \
	count(*) as datapointscount from public.devices group by device_id;"

show-latest-10:
	docker exec -it psql-container \
	psql -U postgres -d main \
	-c "select * from ( \
	select device_id, temperature, location, \
	json_extract_path_text(location::json, 'latitude') as latitude, \
	json_extract_path_text(location::json, 'longitude') as longitude, time, \
	row_number() over (partition by device_id order by time desc) as rownum \
	from public.devices) a where rownum <= 10 \
	order by device_id, time desc;"
