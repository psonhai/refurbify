#!/bin/sh

# 1. Wait for tailscale0 interface to appear
echo "Waiting for Tailscale interface..."
while ! ip -4 addr show tailscale0 | grep -q "inet "; do
  echo "Interface up, but no IP yet. Waiting..."
  sleep 2
done

# 2. Grab the Tailscale IPv4 address
export TS_IP=$(ip -4 addr show tailscale0 | awk '/inet / {print $2}' | cut -d/ -f1)

echo "Tailscale IP found: $TS_IP. Starting K3s..."

# 3. Execute K3s with the dynamic IP
exec k3s server \
  --node-ip=$TS_IP \
  --advertise-address=$TS_IP \
  --flannel-iface=tailscale0 \
  --write-kubeconfig-mode 644