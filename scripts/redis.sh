#!/bin/bash

# Exit on any error
set -e

echo "--- Deploying Redis ---"

# 1. Apply manifests
echo "Applying Redis manifests..."
kubectl apply -f kubernetes/sdv/namespace.yaml
kubectl apply -f kubernetes/sdv/redis-deployment.yaml
kubectl apply -f kubernetes/sdv/redis-service.yaml

# 2. Verify deployment
echo "Verifying Redis deployment..."
kubectl wait --for=condition=ready pod -l app=redis -n sdv --timeout=300s

echo "--- Redis Deployed ---"
