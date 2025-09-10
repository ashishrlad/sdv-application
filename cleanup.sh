#!/bin/bash

# Exit on any error
set -e

echo "Starting cleanup..."

# Stop and disable kubelet
echo "Stopping and disabling kubelet..."
(sudo systemctl stop kubelet && sudo systemctl disable kubelet) || echo "kubelet not found, skipping..."


echo "Resetting kubeadm..."
# Kill process using port 6443
echo "Killing process using port 6443..."
sudo fuser -k 6443/tcp || echo "No process found using port 6443."
(sudo kubeadm reset -f) || echo "kubeadm not found, skipping..."

# Unhold and remove kubernetes packages
echo "Removing Kubernetes packages..."
(sudo apt-mark unhold kubeadm kubectl kubelet && sudo apt-get purge -y kubeadm kubectl kubelet) || echo "Kubernetes packages not found, skipping..."


# Remove directories
echo "Removing directories..."
sudo rm -rf /etc/kubernetes
sudo rm -rf $HOME/.kube
sudo rm -rf /var/lib/etcd
sudo rm -rf /etc/containerd
sudo rm -rf /etc/cni

# Flush iptables
echo "Flushing iptables..."
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X

echo "Cleanup complete."
echo "Note: /data/mysql-db-data/ and /data/minio-storage/ have not been removed."
