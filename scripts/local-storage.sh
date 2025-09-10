#!/bin/bash

# Exit on any error
set -e

echo "--- Deploying Local StorageClass ---"

kubectl apply -f kubernetes/cluster-level/storageclass/local-storage.yaml

echo "--- Local StorageClass Deployed ---"
