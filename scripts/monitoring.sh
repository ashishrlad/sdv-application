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

echo "--- Deploying Monitoring Stack ---"

kubectl apply -f kubernetes/monitoring/namespace.yaml

# 1. Deploy Node Exporter
echo "Deploying Node Exporter..."
kubectl apply -f kubernetes/monitoring/node-exporter-daemonset.yaml
kubectl apply -f kubernetes/monitoring/node-exporter-service.yaml

# 2. Get node name
sudo mkdir -p /data/grafana-data
sudo mkdir -p /data/prometheus-data
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

# 3. Substitute node name in PV and ConfigMap manifests
sed "s/<NODE_NAME>/$NODE_NAME/g" kubernetes/cluster-level/pv/prometheus-pv.yaml > kubernetes/cluster-level/pv/prometheus-pv.yaml.tmp
sed "s/<NODE_NAME>/$NODE_NAME/g" kubernetes/cluster-level/pv/grafana-pv.yaml > kubernetes/cluster-level/pv/grafana-pv.yaml.tmp
sed "s/<NODE_NAME>/$NODE_NAME/g" kubernetes/monitoring/prometheus-configmap.yaml > kubernetes/monitoring/prometheus-configmap.yaml.tmp

# 4. Apply manifests
echo "Applying Monitoring manifests..."
kubectl apply -f kubernetes/monitoring/namespace.yaml
kubectl apply -f kubernetes/cluster-level/pv/prometheus-pv.yaml.tmp
kubectl apply -f kubernetes/monitoring/prometheus-pvc.yaml
kubectl apply -f kubernetes/monitoring/prometheus-configmap.yaml.tmp
kubectl apply -f kubernetes/monitoring/prometheus-deployment.yaml
kubectl apply -f kubernetes/monitoring/prometheus-service.yaml
kubectl delete pod -l app=prometheus -n monitoring

# Deploy kube-state-metrics
echo "Deploying kube-state-metrics..."
kubectl apply -k kubernetes/monitoring/kube-state-metrics/

kubectl apply -f kubernetes/cluster-level/pv/grafana-pv.yaml.tmp
kubectl apply -f kubernetes/monitoring/grafana-pvc.yaml
kubectl apply -f kubernetes/monitoring/grafana-datasource-configmap.yaml
kubectl apply -f kubernetes/monitoring/grafana-dashboard-configmap.yaml
kubectl apply -f kubernetes/monitoring/grafana-config.yaml
kubectl apply -f kubernetes/monitoring/grafana-deployment.yaml
kubectl apply -f kubernetes/monitoring/grafana-service.yaml

# Replace localhost with KUBE_API_IP in Grafana and Prometheus deployments
sed -i "s|http://localhost:3000/grafana|http://$KUBE_API_IP:30092/grafana|g" kubernetes/monitoring/grafana-deployment.yaml
sed -i "s|http://localhost:9090/prometheus|http://$KUBE_API_IP:30091/prometheus|g" kubernetes/monitoring/prometheus-deployment.yaml

# 5. Clean up temporary files
rm kubernetes/cluster-level/pv/prometheus-pv.yaml.tmp
rm kubernetes/cluster-level/pv/grafana-pv.yaml.tmp
rm kubernetes/monitoring/prometheus-configmap.yaml.tmp

# 6. Verify deployments
echo "Verifying Monitoring deployments..."
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s

echo "--- Monitoring Stack Deployed ---"