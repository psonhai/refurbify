FROM python:3.14-slim

COPY requirements.txt /
RUN pip install --no-cache-dir -r requirements.txt

ENV PYTHONUNBUFFERED=1

WORKDIR /