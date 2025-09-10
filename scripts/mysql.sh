#!/bin/bash

# Exit on any error
set -e

echo "--- Deploying MySQL ---"

# 1. Create storage directory
echo "Creating /data/mysql-db-data/ directory..."
sudo mkdir -p /data/mysql-db-data
sudo chown -R 999:999 /data/mysql-db-data

# 2. Get node name
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# 3. Substitute node name in PV manifest
sed "s/<NODE_NAME>/$NODE_NAME/g" kubernetes/cluster-level/pv/mysql-pv.yaml > kubernetes/cluster-level/pv/mysql-pv.yaml.tmp

# 4. Apply manifests
echo "Applying MySQL manifests..."
kubectl apply -f kubernetes/sdv/namespace.yaml
kubectl apply -f kubernetes/sdv/mysql-secret.yaml
kubectl apply -f kubernetes/sdv/mysql-configmap.yaml
kubectl apply -f kubernetes/cluster-level/pv/mysql-pv.yaml.tmp
kubectl apply -f kubernetes/sdv/mysql-pvc.yaml
kubectl apply -f kubernetes/sdv/mysql-deployment.yaml
kubectl apply -f kubernetes/sdv/mysql-service.yaml

# 5. Clean up temporary file
rm kubernetes/cluster-level/pv/mysql-pv.yaml.tmp

# 6. Verify deployment
echo "Verifying MySQL deployment..."
kubectl wait --for=condition=ready pod -l app=mysql -n sdv --timeout=300s

echo "--- MySQL Deployed ---"