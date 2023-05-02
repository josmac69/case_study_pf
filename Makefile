.PHONY: start-production open-psql run-statistics

start-production:
	docker compose up --build

open-psql:
	docker exec -it psql-container psql -U postgres -d main

run-statistics:
	docker exec -it psql-container \
	psql -U postgres -d main \
	-c "select device_id, min(temperature) as mintemp, max(temperature) as maxtemp, \
	count(*) as datapointscount from public.devices group by device_id;"
