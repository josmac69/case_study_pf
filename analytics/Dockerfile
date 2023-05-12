FROM python:3-slim

COPY requirements.txt /pip/requirements.txt

RUN apt-get update && \
    apt-get install -y libpq-dev gcc && \
    pip install --verbose -r /pip/requirements.txt

WORKDIR /app

CMD [ "python", "analytics.py" ]