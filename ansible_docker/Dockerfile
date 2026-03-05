FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    ssh \
    git \
    curl \
    && pip install ansible \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ansible

CMD ["python", "ansible_broadcast_listener.py"]