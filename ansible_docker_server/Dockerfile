FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && \
    apt-get install -y sshpass openssh-client && \
    rm -rf /var/lib/apt/lists/*

# Install Ansible
RUN pip install --no-cache-dir ansible

# Create working directory
WORKDIR /ansible

# Copy files (optional)
COPY . /ansible