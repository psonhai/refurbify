### need review, ai generated code, may contain errors, please review carefully before use ###

import pika
import json
import subprocess
import os
from dotenv import load_dotenv
import logging
import sys

# Configure logging to stderr
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    stream=sys.stderr
)
logger = logging.getLogger(__name__)

load_dotenv()

RABBITMQ_HOSTNAME = os.getenv("RABBITMQ_HOSTNAME", "localhost")
RABBITMQ_USER = os.getenv("RABBITMQ_DEFAULT_USER")
RABBITMQ_PASS = os.getenv("RABBITMQ_DEFAULT_PASS")
QUEUE_NAME = "node_events"

class Worker:
    def __init__(self):
        pass

    def callback(self, ch, method, properties, body):
        host = json.loads(body)
        hostname = host['hostname']
        addresses = host['addresses']
        # Assuming first address is the one to use
        ip = addresses[0]

        logger.info(f"Received message for host: {hostname} with IP: {ip}")
        # Run ansible-playbook for a single target without a temp inventory file
        playbook_path = './server_files/playbook.yml'
        result = subprocess.run([
            'ansible-playbook',
            '-i', f'{ip},',
            '--user', 'Student',
            '--private-key', './server_files/openssh_key',
            '--ssh-extra-args', '-o StrictHostKeyChecking=no',
            '-e', 'ansible_connection=ssh ansible_shell_type=powershell ansible_shell_executable=powershell.exe ansible_remote_tmp=/tmp/ansible-tmp',
            '-vvv',
            playbook_path
        ], capture_output=True, text=True)
        
        logger.info(result.stdout)
        if result.stderr:
            logger.error(result.stderr)

    def run(self):
        # RabbitMQ connection
        connection = pika.BlockingConnection(pika.ConnectionParameters(host=RABBITMQ_HOSTNAME, credentials=pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)))
        channel = connection.channel()
        channel.queue_declare(queue=QUEUE_NAME)
        channel.basic_consume(queue=QUEUE_NAME, on_message_callback=self.callback, auto_ack=True)

        logger.info('Waiting for messages...')
        channel.start_consuming()

if __name__ == '__main__':
    worker = Worker()
    worker.run()