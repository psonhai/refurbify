# FROM python:3.14-slim
FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    ssh \
    git \
    curl \
    # && pip install ansible \
    && rm -rf /var/lib/apt/lists/*

# RUN pip install --no-cache-dir ansible pika

WORKDIR /ansible