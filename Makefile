.PHONY: create-env \
	start-production \
	stop-all \
	pg-env \
	open-psql \
	show-stats-per-hour \
	show-stats-per-1min \
	show-latest-10

JUPYTER_IMAGE = "myjupyter:latest"
NETWORK_NAME = "case_study_pf"

create-env:
	mkdir -p jupyter/notebooks
	touch jupyter/notebooks/.gitkeep
	docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || docker network create $(NETWORK_NAME)

start-production: create-env
	docker compose up --build

stop-all:
	docker compose down

open-psql:
	docker exec -it psql-container psql -U postgres -d main

pg-env:
	docker exec -it psql-container \
	psql -U postgres -d main \
	-c "CREATE EXTENSION IF NOT EXISTS cube; \
	CREATE EXTENSION IF NOT EXISTS earthdistance;"

show-stats-per-hour: pg-env
	docker exec -it psql-container \
	psql -U postgres -d main \
	-c "select device_id, \
		date_trunc('hour', to_timestamp(time::bigint)) as date_hour, \
		min(temperature) as mintemp, \
		max(temperature) as maxtemp, \
		count(*) as datapointscount \
		from public.devices \
		group by device_id, date_hour \
		order by device_id, date_hour;"

show-stats-per-1min: pg-env
	docker exec -it psql-container \
	psql -U postgres -d main \
	-c "select device_id, \
		date_trunc('minute', to_timestamp(time::bigint)) as date_1min, \
		min(temperature) as mintemp, \
		max(temperature) as maxtemp, \
		count(*) as datapointscount \
		from public.devices \
		group by device_id, date_1min \
		order by device_id, date_1min;"

show-latest-10: pg-env
	docker exec -it psql-container \
	psql -U postgres -d main \
	-c "with srcdata as ( \
		select * from ( \
		select device_id, temperature, \
		location, \
		json_extract_path_text(location::json, 'latitude') as latitude, \
		json_extract_path_text(location::json, 'longitude') as longitude, \
		lag(location) over w as prev_location, \
		json_extract_path_text( (lag(location) over w)::json, 'latitude') as prev_latitude, \
		json_extract_path_text( (lag(location) over w)::json, 'longitude') as prev_longitude, \
		time, \
		row_number() over (partition by device_id order by time desc) as rownum \
		from public.devices \
		window w as (partition by device_id order by time) ) a ) \
		select device_id, time, location, prev_location, \
		( acos(sin(latitude::float) * sin(prev_latitude::float) + \
		cos(latitude::float) * cos(prev_latitude::float) * \
		cos(prev_longitude::float - longitude::float)) * 6371 ) \
		AS distance_from_previous \
		from srcdata \
		where rownum <= 10 \
		order by device_id, time desc;"

build-jupyter-image:
	cd jupyter/image/ && \
	docker build --progress=plain --no-cache -t "$(JUPYTER_IMAGE)" -f Dockerfile . && \
	cd ../../

run-jupyter: create-env
	docker run -i -t \
	-v ${PWD}/jupyter/notebooks:/opt/notebooks \
	-p 8888:8888 \
	--network $(NETWORK_NAME) \
	"$(JUPYTER_IMAGE)" /bin/bash \
	-c "/opt/conda/bin/conda install jupyter -y --quiet && \
	/opt/conda/bin/jupyter notebook \
	--notebook-dir=/opt/notebooks --ip='*' --port=8888 \
	--no-browser --allow-root"
