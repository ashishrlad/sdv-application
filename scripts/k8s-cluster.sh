#!/bin/bash

# Exit on any error
set -e

# Function to display usage
usage() {
    echo "Usage: $0 --ip <kube-api-ip> --k8s-version <kubernetes-version>"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ip) KUBE_API_IP="$2"; shift ;;
        --k8s-version) K8S_VERSION="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Check if parameters are set
if [ -z "$KUBE_API_IP" ] || [ -z "$K8S_VERSION" ]; then
    echo "Error: Missing required arguments."
    usage
fi

echo "--- Setting up Kubernetes Cluster ---"

# 1. Initialize the Kubernetes cluster using kubeadm
echo "Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=10.195.0.0/16 --apiserver-advertise-address=$KUBE_API_IP --kubernetes-version=$K8S_VERSION

# 2. Configure kubeconfig for the current user and root
echo "Configuring kubeconfig..."
if [ -f "$HOME/.kube/config" ]; then
    mv $HOME/.kube/config $HOME/.kube/config.backup
fi
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

if [ -f "/root/.kube/config" ]; then
    sudo mv /root/.kube/config /root/.kube/config.backup
fi
sudo mkdir -p /root/.kube
sudo cp /etc/kubernetes/admin.conf /root/.kube/config

# 3. Install Calico CNI
echo "Installing Calico CNI..."
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml

# 4. Remove the control-plane taint
echo "Removing control-plane taint..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "--- Kubernetes Cluster Setup Finished ---"
