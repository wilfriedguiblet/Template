FROM python:3.10.14-slim

WORKDIR /pipeline
COPY requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
