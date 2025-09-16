#!/bin/bash

# Exit on any error
set -e

# Logging setup
LOG_FILE="cleanup-$(date +%Y%m%d-%H%M%S).log"
exec &> >(tee -a "$LOG_FILE")

echo "Starting cleanup..."

# Stop and disable kubelet
echo "Stopping and disabling kubelet..."
sudo systemctl stop kubelet || echo "kubelet not found, skipping..."
sudo systemctl disable kubelet || echo "kubelet not found, skipping..."

# Reset kubeadm
echo "Resetting kubeadm..."
sudo kubeadm reset -f || echo "kubeadm not found, skipping..."

# Remove kubernetes packages
echo "Removing Kubernetes packages..."
sudo apt-mark unhold kubeadm kubectl kubelet || echo "Kubernetes packages not on hold."
sudo apt-get purge -y kubeadm kubectl kubelet || echo "Kubernetes packages not found, skipping..."
sudo apt-get autoremove -y

# Remove directories
echo "Removing directories..."
sudo rm -rf /etc/kubernetes
sudo rm -rf $HOME/.kube
sudo rm -rf /var/lib/etcd
sudo rm -rf /etc/containerd
sudo rm -rf /etc/cni
sudo rm -rf sdv-application

# Flush iptables
echo "Flushing iptables..."
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

# Reload systemd
echo "Reloading systemd..."
sudo systemctl daemon-reload

# Find and remove any remaining kubelet binaries
echo "Searching for and removing any remaining kubelet binaries..."
sudo find / -name "kubelet" -type f -delete

echo "Cleanup complete."
echo "Note: /data/mysql-db-data/ and /data/minio-storage/ have not been removed."
