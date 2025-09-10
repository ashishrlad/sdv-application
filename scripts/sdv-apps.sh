#!/bin/bash

# Exit on any error
set -e

echo "--- Deploying SDV Applications ---"

# 1. Apply manifests
echo "Applying SDV Application manifests..."
kubectl apply -f kubernetes/sdv/namespace.yaml
kubectl apply -f kubernetes/sdv/sdv-middleware-deployment.yaml
kubectl apply -f kubernetes/sdv/sdv-middleware-service.yaml
kubectl apply -f kubernetes/sdv/sdv-web-deployment.yaml
kubectl apply -f kubernetes/sdv/sdv-web-service.yaml

# 2. Verify deployments
echo "Verifying SDV Application deployments..."
kubectl wait --for=condition=ready pod -l app=sdv-middleware -n sdv --timeout=300s
kubectl wait --for=condition=ready pod -l app=sdv-web -n sdv --timeout=300s

echo "--- SDV Applications Deployed ---"
