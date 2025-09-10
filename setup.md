# Setup Guide

This document provides the steps to set up the environment using the provided bash scripts.

## Prerequisites

-   An Ubuntu 22.04 LTS machine.
-   Sudo privileges on the machine.
-   Internet connectivity to download packages.

## Installation

1.  **Clone the repository** (or download the scripts) to your target machine.
    ```bash
    git clone <repository_url>
    cd <repository_directory>
    ```

2.  **Make the main installation script executable:**
    ```bash
    chmod +x install.sh
    ```

3.  **Run the installation script:**
    The `install.sh` script requires two arguments:
    -   `--ip`: The private IP address of the machine, which will be used for the Kube-apiserver endpoint.
    -   `--k8s-version`: The version of Kubernetes to install (e.g., `1.31.0`).

    Example:
    ```bash
    ./install.sh --ip 192.168.1.100 --k8s-version 1.31.0
    ```

5.  **Installation Process:**
    The `install.sh` script will perform the following actions:
    -   Install Kubernetes prerequisites (kubeadm, kubelet, kubectl, containerd, docker).
    -   Configure container runtimes (containerd and docker) to use `systemd` as the cgroup driver.
    -   Install and configure HAProxy.
    -   Initialize the Kubernetes cluster using `kubeadm`.
    -   Install Calico CNI.
    -   Remove the control-plane taint to allow pods to be scheduled on the master node.
    -   Configure `kubeconfig` for the current user and the root user.
    -   Deploy the following applications in the specified order:
        1.  Local storage class
        2.  MinIO
        3.  MySQL
        4.  Redis
        5.  SDV Middleware
        6.  SDV Web
        7.  Monitoring Stack (Prometheus, Grafana, Node Exporter)

6.  **Verification:**
    After the installation is complete, a summary of successfully deployed components will be displayed. The script will also perform verification checks for each component to ensure they are running correctly.

## Cleanup

To clean up the installation and remove all the components, run the `cleanup.sh` script.

1.  **Make the cleanup script executable:**
    ```bash
    chmod +x cleanup.sh
    ```

2.  **Run the cleanup script:**
    ```bash
    ./cleanup.sh
    ```

The cleanup script will:
-   Remove Kubernetes packages (kubeadm, kubectl, kubelet).
-   Delete configuration directories (`/etc/kubernetes`, `$HOME/.kube`, etc.).
-   Flush iptables rules.
-   **Note:** The script will not remove persistent data directories (`/mnt/mysql-db-data/` and `/mnt/minio-storage/`).
