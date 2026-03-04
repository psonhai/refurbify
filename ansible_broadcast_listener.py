import socket
import queue
import threading
import subprocess
from concurrent.futures import ThreadPoolExecutor

# Configuration
UDP_PORT = 5000
BUFFER_SIZE = 1024
MAX_WORKERS = 5

task_queue = queue.Queue()
running_hosts = set()  # To track hosts currently being processed

def udp_listener():
    """Listen for UDP broadcast messages and push to queue."""
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("", UDP_PORT))  # Listen on all interfaces

    print(f"Listening for UDP broadcast on port {UDP_PORT}...")

    while True:
        data, addr = sock.recvfrom(BUFFER_SIZE)
        message = data.decode().strip()
        print(f"Received from {addr}: {message}")

        # IMPORTANT - WORK TO BE DONE: ENSURE THE MESSAGE IS IN RIGHT FORMAT AND VALIDATE IT BEFORE PROCESSING

        if message not in running_hosts:
            running_hosts.add(message)
            task_queue.put((message, addr))


def run_ansible(target_host):
    """Execute ansible-playbook for target host."""
    print(f"Running Ansible for {target_host}")

    cmd = [
        "ansible-playbook",
        "-i", f"{target_host},",
        "playbook.yml",
        "-u", "Student",
        "--private-key", "/home/hai06/.ssh/ansible_ed25519",
        "-e ansible_connection=ssh ansible_shell_type=powershell ansible_shell_executable=powershell.exe ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'",
    ]

    cmd_str = " ".join(cmd)

    print(cmd_str)

    result = subprocess.run(cmd, capture_output=True, text=True)

    print(f"Ansible output for {target_host}:")
    print(result.stdout)

    if result.returncode != 0:
        print(f"Error: {result.stderr}")


def worker():
    """Worker that processes queue items."""
    while True:
        message, addr = task_queue.get()

        try:
            target_host = message  # assume broadcast sends IP
            run_ansible(target_host)
        except Exception as e:
            print(f"Worker error: {e}")
        finally:
            task_queue.task_done()


def main():
    # Start UDP listener thread
    threading.Thread(target=udp_listener, daemon=True).start()

    # Start worker pool
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        for _ in range(MAX_WORKERS):
            executor.submit(worker)

        # Block forever
        task_queue.join()


if __name__ == "__main__":
    main()