import time
import json
import requests
import pika
from cachetools import TTLCache
from dotenv import load_dotenv
import os
import logging
import sys

load_dotenv()  # reads .env from current directory

TAILNET = os.getenv("TAILNET_NAME")
CLIENT_ID = os.getenv("TS_NODETRACKER_ID")
CLIENT_SECRET = os.getenv("TS_NODETRACKER_SECRET")

RABBITMQ_HOSTNAME = os.getenv("RABBITMQ_HOSTNAME", "localhost")
RABBITMQ_USER = os.getenv("RABBITMQ_DEFAULT_USER")
RABBITMQ_PASS = os.getenv("RABBITMQ_DEFAULT_PASS")
QUEUE_NAME = "node_events"
POLL_INTERVAL = 60 # run every 60s

# Configure logging to stderr
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    stream=sys.stderr
)
logger = logging.getLogger(__name__)

# ----------------------------
# OAuth client
# ----------------------------

class OAuthClient:
    def __init__(self, client_id, client_secret):
        self.client_id = client_id
        self.client_secret = client_secret
        self.token = None
        self.expiry = 0

    def get_token(self):
        if time.time() < self.expiry - 60:
            return self.token

        r = requests.post(
            "https://api.tailscale.com/api/v2/oauth/token",
            auth=(self.client_id, self.client_secret),
            data={"grant_type": "client_credentials"},
        )
        r.raise_for_status()

        data = r.json()
        self.token = data["access_token"]
        self.expiry = time.time() + data["expires_in"]

        return self.token

# ----------------------------
# Node Tracker
# ----------------------------

class NodeTracker:
    def __init__(self, mq, oauth):
        self.mq = mq
        self.oauth = oauth
        self.seen = TTLCache(maxsize=5000, ttl=1800)

    def fetch_nodes(self):
        logger.info("Fetching nodes from Tailscale API...")
        token = self.oauth.get_token() # Get a valid token (refresh if needed)

        r = requests.get(
            f"https://api.tailscale.com/api/v2/tailnet/{TAILNET}/devices",
            headers={"Authorization": f"Bearer {token}"}
        )
        r.raise_for_status()
        return r.json()["devices"]

    @staticmethod
    def has_tag(node, tag):
        return tag in node["tags"]

    def handle_node(self, node):
        node_id = node["nodeId"]

        if node_id in self.seen:
            return

        self.seen[node_id] = True

        event = {
            "nodeId": node.get("nodeId"),
            "hostname": node.get("hostname"),
            "addresses": node.get("addresses", []),
            "os": node.get("os"),
            "lastSeen": node.get("lastSeen"),
            "authorized": node.get("authorized"),
            "tags": node.get("tags", []),
        }

        if self.has_tag(node, "Client"):
            self.mq.publish(event)
            logger.info("Published event: ", event)
        else:
            logger.info("Detected a server, ignore!")

    def run(self):
        logger.info("RabbitMQ NodeTracker started...")

        while True:
            try:
                for node in self.fetch_nodes():
                    self.handle_node(node)

            except Exception as e:
                print("Error:", e)

            time.sleep(POLL_INTERVAL)

# ----------------------------
# Message Queue
# ----------------------------

class MQ:
    def __init__(self):
        while True:
            try:
                self.conn = pika.BlockingConnection(
                    pika.ConnectionParameters(
                        host=RABBITMQ_HOSTNAME,
                        virtual_host="/",
                        credentials=pika.PlainCredentials(RABBITMQ_USER, RABBITMQ_PASS)
                    )
                )
                break
            except pika.exceptions.AMQPConnectionError:
                logger.info("Waiting for RabbitMQ...")
                time.sleep(3)

        self.channel = self.conn.channel()
        self.channel.queue_declare(queue=QUEUE_NAME, durable=True)

    def publish(self, event: dict):
        self.channel.basic_publish(
            exchange="",
            routing_key=QUEUE_NAME,
            body=json.dumps(event),
            properties=pika.BasicProperties(
                delivery_mode=2  # persistent message
            ),
        )

# ----------------------------
# Main Function
# ----------------------------

if __name__ == "__main__":
    oauth = OAuthClient(CLIENT_ID, CLIENT_SECRET)
    mq = MQ()

    tracker = NodeTracker(mq, oauth)
    tracker.run()