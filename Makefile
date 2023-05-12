# main Makefile for the project

JUPYTER_IMAGE = "myjupyter:latest"
NETWORK_NAME = "case_study_pf"
ANALYTICS_IMAGE = "case_study_pf_analytics"

POSTGRESQL_CONTAINER = "psql-container"
POSTGRESQL_USER = "postgres"
POSTGRESQL_PASSWORD = "password"
POSTGRESQL_DATABASE = "main"

init:
	@echo "Initializing the project"
	docker compose -f docker-compose.airflow.yaml up airflow-init

create-env:
	mkdir -p ./dags ./plugins ./logs ./data
	chmod -R 777 ./dags ./plugins ./logs ./data
	mkdir -p jupyter/notebooks
	touch jupyter/notebooks/.gitkeep
	docker network inspect $(NETWORK_NAME) >/dev/null 2>&1 || docker network create $(NETWORK_NAME)

start-dbs: create-env
	docker compose -f docker-compose.dbs.yaml up --build

start-airflow: create-env
	docker compose -f docker-compose.airflow.yaml up --build

start-all: start-dbs start-airflow

stop-all:
	docker compose -f docker-compose.airflow.yaml down --remove-orphans
	docker compose -f docker-compose.dbs.yaml down --remove-orphans

open-psql:
	docker exec -it \
	$(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) \
	-d $(POSTGRESQL_DATABASE)

open-mysql:
	docker exec -it \
	mysql56-container \
	mysql -u root \
	-proot analytics

pg-env:
	docker exec -it $(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) -d $(POSTGRESQL_DATABASE) \
	-c "CREATE EXTENSION IF NOT EXISTS cube; \
	CREATE EXTENSION IF NOT EXISTS earthdistance;"

show-stats-per-hour: pg-env
	docker exec -it \
	$(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) \
	-d $(POSTGRESQL_DATABASE) \
	-f /sql/stats_per_hour.sql

show-latest-10: pg-env
	docker exec -it \
	$(POSTGRESQL_CONTAINER) \
	psql -U $(POSTGRESQL_USER) \
	-d $(POSTGRESQL_DATABASE) \
	-f /sql/latest_10_records_per_probe.sql

build-jupyter-image:
	cd jupyter/image/ && \
	docker build --progress=plain \
	--no-cache -t "$(JUPYTER_IMAGE)" \
	-f Dockerfile . && \
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

build-analytics: create-env
	cd analytics/ && \
	docker build --progress=plain \
	--no-cache -t "$(ANALYTICS_IMAGE)" \
	-f Dockerfile . && \
	cd ../

run-analytics: create-env
	docker run -i -t \
	--network $(NETWORK_NAME) \
	-v ${PWD}/analytics:/app \
	-e POSTGRESQL_CS='postgresql+psycopg2://$(POSTGRESQL_USER):$(POSTGRESQL_PASSWORD)@psql_db:5432/$(POSTGRESQL_DATABASE)' \
    -e MYSQL_CS='mysql+pymysql://nonroot:nonroot@mysql_db/analytics?charset=utf8' \
	"$(ANALYTICS_IMAGE)" /bin/bash \
	-c "python3 /app/analytics.py"

.PHONY: create-env \
	start-dbs \
	start-airflow \
	start-all \
	stop-all \
	pg-env \
	open-psql \
	show-stats-per-hour \
	show-latest-10 \
	build-jupyter-image \
	run-jupyter \
	open-mysql \
	build-analytics \
	run-analytics
