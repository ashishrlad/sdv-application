# SDV Protean - Automated Kubernetes Setup

This project provides a set of bash scripts to automate the setup of a single-node Kubernetes cluster on Ubuntu 22.04 LTS. It includes the installation of a Kubernetes cluster, along with various services like MinIO, MySQL, Redis, and a monitoring stack.

## Prerequisites

-   An Ubuntu 22.04 LTS machine.
-   Sudo privileges on the machine.
-   Internet connectivity to download packages.
-   At least 2 CPUs and 4GB of RAM are recommended.

## Installation

1.  **Clone this repository:**
    ```bash
    git clone <repository_url>
    cd sdv-protean
    ```

2.  **Run the installation script:**
    The `install.sh` script is the main entry point for the installation. It requires two arguments:
    -   `--ip`: The private IP address of the machine, which will be used for the Kube-apiserver endpoint.
    -   `--k8s-version`: The version of Kubernetes to install (e.g., `1.31.0`).

    Example:
    ```bash
    chmod +x install.sh
    ./install.sh --ip 192.168.1.100 --k8s-version 1.31.0
    ```

3.  **Installation Process:**
    The script will perform the following steps:
    -   Install all necessary prerequisites, including `containerd`, `docker`, `kubeadm`, `kubelet`, and `kubectl`.
    -   Configure `containerd` and `docker` to use the `systemd` cgroup driver.
    -   Install and configure HAProxy.
    -   Initialize a single-node Kubernetes cluster using `kubeadm`.
    -   Install the Calico CNI plugin.
    -   Deploy the following applications:
        -   A local storage provisioner.
        -   MinIO (object storage).
        -   MySQL (database).
        -   Redis (in-memory data store).
        -   A sample SDV application (middleware and web).
        -   A monitoring stack with Prometheus and Grafana.

4.  **Verification:**
    Upon completion, the script will display a summary of all the deployed components and their access URLs. All logs from the installation process are stored in the `installation.log` file.

## Cleanup

To remove all the components installed by the script, you can run the `cleanup.sh` script.

```bash
chmod +x cleanup.sh
./cleanup.sh
```

This will:
-   Remove all Kubernetes components.
-   Delete all related configuration files.
-   Flush iptables rules.

**Note:** The cleanup script will **not** delete the persistent data stored in `/mnt/mysql-db-data/` and `/mnt/minio-storage/`.

## Deployed Services

Once the installation is successful, you can access the services at the following NodePort URLs:

-   **MinIO Console:** `http://<YOUR_NODE_IP>:30090`
-   **Grafana:** `http://<YOUR_NODE_IP>:30092`
-   **Prometheus:** `http://<YOUR_NODE_IP>:30091`
-   **SDV Web App:** `http://<YOUR_NODE_IP>:30080`
