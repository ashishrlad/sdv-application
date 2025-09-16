#!/bin/bash
cd "$(dirname "$0")"

# Exit on any error
set -e

# Logging setup
LOG_FILE="install-$(date +%Y%m%d-%H%M%S).log"
exec &> >(tee -a "$LOG_FILE")

# Prompt for Kube API IP
read -p "Enter the Kube API IP address: " KUBE_API_IP

# Prompt for Kubernetes Version with default
read -p "Enter the Kubernetes version (e.g., 1.32.0, default: 1.32.0): " K8S_VERSION
if [ -z "$K8S_VERSION" ]; then
    K8S_VERSION="1.32.0"
fi

echo "Starting installation with Kube API IP: $KUBE_API_IP and Kubernetes Version: $K8S_VERSION"

# --- Create scripts directory ---
mkdir -p scripts

echo "Phase 1: Core Framework and Environment Setup"
./scripts/k8s-prereqs.sh --k8s-version $K8S_VERSION
./scripts/haproxy.sh

echo "Phase 2: Kubernetes Cluster and Basic Services"
./scripts/k8s-cluster.sh --ip $KUBE_API_IP --k8s-version $K8S_VERSION
  #mkdir -p $HOME/.kube
  #sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
  #sudo chown $USER:$USER $HOME/.kube/config
./scripts/local-storage.sh
./scripts/minio.sh --ip $KUBE_API_IP
./scripts/mysql.sh
./scripts/redis.sh

echo "Phase 3: Application Deployment and Monitoring"
./scripts/sdv-apps.sh
./scripts/monitoring.sh --ip $KUBE_API_IP

final_summary() {
    echo "--- Installation Summary ---"
    echo "Kubernetes cluster is running."
    echo "Namespaces:"
    kubectl get namespaces
    echo "Nodes:"
    kubectl get nodes -o wide
    echo "Pods:"
    kubectl get pods --all-namespaces -o wide
    echo "Services:"
    kubectl get services --all-namespaces -o wide
    echo "---"
    echo "MinIO Console: http://<YOUR_NODE_IP>:30090"
    echo "Grafana: http://<YOUR_NODE_IP>:30092"
    echo "Prometheus: http://<YOUR_NODE_IP>:30091"
    echo "SDV Web App: http://<YOUR_NODE_IP>:30080"
    echo "--- "
    echo "Installation has completed successfully!"
}

final_summary

echo "Installation complete!"
