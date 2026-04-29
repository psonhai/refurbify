FROM python:3.14-slim

RUN apt-get update && apt-get install -y \
    git curl iproute2 iptables ca-certificates \
    && pip install ansible \
    && curl -fsSL https://tailscale.com/install.sh | sh \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir ansible pika

WORKDIR /ansible