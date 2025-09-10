#!/bin/bash

# Exit on any error
set -e

# Function to display usage
usage() {
    echo "Usage: $0 --ip <kube-api-ip>"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ip) KUBE_API_IP="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; usage ;;
    esac
    shift
done

# Check if parameters are set
if [ -z "$KUBE_API_IP" ]; then
    echo "Error: Missing required arguments."
    usage
fi

echo "--- Deploying MinIO ---"

# 1. Create storage directory
echo "Creating /data/minio-storage/ directory..."
sudo mkdir -p /data/minio-storage
sudo chown -R 1000:1000 /data/minio-storage

# 2. Get node name
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# 3. Substitute node name in PV manifest
sed "s/<NODE_NAME>/$NODE_NAME/g" kubernetes/cluster-level/pv/minio-pv.yaml > kubernetes/cluster-level/pv/minio-pv.yaml.tmp

# 4. Apply manifests
echo "Applying MinIO manifests..."
kubectl apply -f kubernetes/minio/namespace.yaml
kubectl apply -f kubernetes/minio/secret.yaml
kubectl apply -f kubernetes/cluster-level/pv/minio-pv.yaml.tmp
kubectl apply -f kubernetes/minio/pvc.yaml
kubectl apply -f kubernetes/minio/deployment.yaml
kubectl apply -f kubernetes/minio/service.yaml

# 5. Clean up temporary file
rm kubernetes/cluster-level/pv/minio-pv.yaml.tmp

# 6. Verify deployment
echo "Verifying MinIO deployment..."
sleep 10
kubectl wait --for=condition=ready pod -l app=minio -n minio --timeout=300s

echo "--- MinIO Deployed ---"