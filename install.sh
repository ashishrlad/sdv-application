#!/bin/bash
cd "$(dirname "$0")"

# Exit on any error
set -e

# Logging setup
LOG_FILE="installation.log"
exec &> >(tee -a "$LOG_FILE")

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

echo "Starting installation with Kube API IP: $KUBE_API_IP and Kubernetes Version: $K8S_VERSION"

# --- Create scripts directory ---
mkdir -p scripts

echo "Phase 1: Core Framework and Environment Setup"
./scripts/k8s-prereqs.sh
./scripts/haproxy.sh

echo "Phase 2: Kubernetes Cluster and Basic Services"
./scripts/k8s-cluster.sh --ip $KUBE_API_IP --k8s-version $K8S_VERSION
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
    kubectl get nodes
    echo "Pods:"
    kubectl get pods --all-namespaces
    echo "Services:"
    kubectl get services --all-namespaces
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
