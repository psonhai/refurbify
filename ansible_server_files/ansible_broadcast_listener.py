#####################################
# UDP Broadcast Ansible Executor
#
# This script listens for UDP broadcast messages from clients on a specified
# port (default 5000) and executes Ansible playbooks on validated hosts.
#
# Features:
# 1. Listens on all interfaces for UDP messages containing IPv4 addresses.
# 2. Validates each message:
#    - Proper IPv4 format
#    - IP within allowed subnet(s)
#    - Rate-limits repeated processing per host (MIN_INTERVAL)
# 3. Uses a thread pool to process multiple hosts concurrently (MAX_WORKERS).
# 4. Runs ansible-playbook via subprocess with specified SSH key and user.
#
# Security Notes:
# - Only processes hosts in ALLOWED_SUBNETS
# - Skips hosts processed within MIN_INTERVAL seconds
# - SSH connections use StrictHostKeyChecking=no and UserKnownHostsFile=/dev/null, bypassing known host because hosts can be assigned same ip address
#####################################

import socket
import queue
import threading
import subprocess
from concurrent.futures import ThreadPoolExecutor
import time
import ipaddress

# =====================
# CONFIGURATION
# =====================
UDP_PORT = 5000
BUFFER_SIZE = 1024
MAX_WORKERS = 8
ALLOWED_SUBNETS = ["192.168.1.0/24"]  # Only accept broadcasts from trusted subnet
MIN_INTERVAL = 90  # Minimum seconds between processing the same host

task_queue = queue.Queue()
running_hosts = {}  # host -> last processed timestamp

# =====================
# HELPER FUNCTIONS
# =====================
def validate_ip_address(ip):
    """Validate that the message is a proper IPv4 address."""
    try:
        socket.inet_aton(ip)
        return True
    except socket.error:
        return False

def validate_subnet(ip):
    """Check if the IP is in allowed subnets."""
    for subnet in ALLOWED_SUBNETS:
        if ipaddress.IPv4Address(ip) in ipaddress.IPv4Network(subnet):
            return True
    return False

# =====================
# WORKER FUNCTIONS
# =====================
def run_ansible(target_host):
    """Execute ansible-playbook for a target host."""
    print(f"[INFO] Running Ansible for {target_host}")

    cmd = [
        "ansible-playbook",
        "-i", f"{target_host},",
        "playbook.yml",
        "-u", "Student",
        "--private-key", "ansible_ssh_key",
        "-e ansible_connection=ssh ansible_shell_type=powershell ansible_shell_executable=powershell.exe ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'",
    ]

    result = subprocess.run(cmd, capture_output=True, text=True)
    print(f"[INFO] Ansible output for {target_host}:\n{result.stdout}")
    if result.returncode != 0:
        print(f"[ERROR] Ansible error for {target_host}:\n{result.stderr}")

def worker():
    """Worker that processes queue items."""
    while True:
        message, addr = task_queue.get()
        try:
            target_host = message
            run_ansible(target_host)
        except Exception as e:
            print(f"[ERROR] Worker error: {e}")
        finally:
            task_queue.task_done()

# =====================
# UDP LISTENER
# =====================
def udp_listener():
    """Listen for UDP broadcast messages and push validated hosts to the queue."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("", UDP_PORT))
    print(f"[INFO] Listening for UDP broadcast on port {UDP_PORT}...")

    while True:
        try:
            data, addr = sock.recvfrom(BUFFER_SIZE)
            ip = data.decode().strip()

            # Validate IP format
            if not validate_ip_address(ip):
                print(f"[WARN] Invalid IP format from {addr}: {ip}")
                continue

            # Validate subnet
            if not validate_subnet(ip):
                print(f"[WARN] IP {ip} not in allowed subnets")
                continue

            # Rate-limit per host
            now = time.time()
            last_time = running_hosts.get(ip, 0)
            if now - last_time < MIN_INTERVAL:
                print(f"[INFO] Skipping {ip}, processed {now-last_time:.1f}s ago")
                continue

            # Passed all checks
            running_hosts[ip] = now
            task_queue.put((ip, addr))
            print(f"[INFO] Queued {ip} for Ansible execution")

        except Exception as e:
            print(f"[ERROR] Listener exception: {e}")

# =====================
# MAIN
# =====================
def main():
    threading.Thread(target=udp_listener, daemon=True).start()
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        for _ in range(MAX_WORKERS):
            executor.submit(worker)
        task_queue.join()

if __name__ == "__main__":
    main()