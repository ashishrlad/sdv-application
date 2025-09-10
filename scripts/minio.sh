#!/bin/bash

# Exit on any error
set -e

echo "--- Deploying MinIO ---"

# 1. Create storage directory
echo "Creating /data/minio-storage/ directory..."
sudo mkdir -p /data/minio-storage

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
kubectl wait --for=condition=ready pod -l app=minio -n minio --timeout=300s

echo "--- MinIO Deployed ---"