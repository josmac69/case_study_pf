FROM python:3-slim

WORKDIR /pip

COPY requirements.txt .

RUN apt-get update && \
    apt-get install -y libpq-dev gcc && \
    pip install --verbose -r /pip/requirements.txt

CMD [ "python", "/app/analytics.py" ]