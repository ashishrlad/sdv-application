#!/bin/bash

# Exit on any error
set -e

echo "--- Running Kubernetes Prerequisites ---"

# 1. Disable swap
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Install containerd and docker
echo "Installing containerd and docker..."
if ! command -v containerd &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y containerd
else
    echo "containerd is already installed."
fi

if ! command -v docker &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y docker.io
else
    echo "docker is already installed."
fi


# 3. Configure cgroup driver for containerd and docker
echo "Configuring cgroup driver..."

# containerd
if [ ! -f /etc/containerd/config.toml ] || ! grep -q "SystemdCgroup = true" /etc/containerd/config.toml; then
    sudo mkdir -p /etc/containerd
    containerd config default | sudo tee /etc/containerd/config.toml
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    sudo systemctl restart containerd
else
    echo "containerd already configured with SystemdCgroup."
fi


# docker
if [ ! -f /etc/docker/daemon.json ] || ! grep -q "native.cgroupdriver=systemd" /etc/docker/daemon.json; then
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
    sudo systemctl restart docker
else
    echo "docker already configured with systemd cgroup driver."
fi


# 4. Load kernel modules
echo "Loading kernel modules..."
if ! lsmod | grep -q "overlay"; then
    sudo modprobe overlay
fi
if ! lsmod | grep -q "br_netfilter"; then
    sudo modprobe br_netfilter
fi
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# 5. Set sysctl params
echo "Setting sysctl params..."
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# 6. Install kubeadm, kubelet, kubectl
echo "Installing Kubernetes components..."

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --k8s-version) K8S_VERSION="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$K8S_VERSION" ]; then
    echo "Error: Missing --k8s-version argument."
    exit 1
fi

K8S_MAJOR_VERSION=$(echo $K8S_VERSION | cut -d. -f1,2)

if ! command -v kubelet &> /dev/null || ! kubelet --version | grep -q "$K8S_VERSION"; then
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/v$K8S_MAJOR_VERSION/deb/Release.key" | sudo gpg --dearmor | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.gpg > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$K8S_MAJOR_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
else
    echo "Kubernetes components version $K8S_VERSION are already installed."
fi


echo "--- Kubernetes Prerequisites Finished ---"