#!/bin/bash

# Exit on any error
set -e

echo "--- Installing and Configuring HAProxy ---"

# 1. Install HAProxy
if ! command -v haproxy &> /dev/null; then
    sudo apt-get update
    sudo apt-get install -y haproxy
else
    echo "HAProxy is already installed."
fi

# 2. Generate self-signed SSL certificate
echo "Generating self-signed SSL certificate..."
sudo mkdir -p /etc/haproxy/certs
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/haproxy/certs/haproxy.key \
    -out /etc/haproxy/certs/haproxy.crt \
    -subj "/CN=localhost"
sudo bash -c 'cat /etc/haproxy/certs/haproxy.key /etc/haproxy/certs/haproxy.crt > /etc/haproxy/certs/haproxy.pem'


# 3. Configure HAProxy
# This will overwrite the config file, which is what we want to ensure our config is applied.
sudo tee /etc/haproxy/haproxy.cfg <<EOF
global
    log /dev/log    local0
    log /dev/log    local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend http_front
   bind *:80
   bind *:443 ssl crt /etc/haproxy/certs/haproxy.pem
   bind *:30090 ssl crt /etc/haproxy/certs/haproxy.pem
   stats uri /haproxy?stats

   acl is_minio dst_port 30090
   #acl path_minio path_beg /minio
   acl path_grafana path_beg /grafana
   acl path_prometheus path_beg /prometheus

   #use_backend minio_back if path_minio
   use_backend minio_back if is_minio
   use_backend grafana_back if path_grafana
   use_backend prometheus_back if path_prometheus
   default_backend http_back

backend http_back
   server web_app 127.0.0.1:30080 check

backend minio_back
   #server minio_server 127.0.0.1:9001 check
   server minio_server 127.0.0.1:30090 check

backend grafana_back
   server grafana_server 127.0.0.1:30092 check

backend prometheus_back
   server prometheus_server 127.0.0.1:30091 check
EOF

# 4. Enable and start HAProxy
sudo systemctl enable haproxy
sudo systemctl restart haproxy

echo "--- HAProxy Installation and Configuration Finished ---"
