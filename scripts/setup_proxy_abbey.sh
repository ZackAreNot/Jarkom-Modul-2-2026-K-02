#!/bin/bash
# ==============================================================================
# Setup Reverse Proxy Nginx pada Node Abbey (Subnet 4)
# Mengarah ke Area Core: Oblada (192.212.1.6) & Molly (192.212.1.7)
# Load balancing: Round-robin (default)
# Header forwarding: Host & X-Real-IP
# ==============================================================================
set -e

echo "[+] Updating apt and installing Nginx on Abbey..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

echo "[+] Configuring Nginx Reverse Proxy for Area Core on Abbey..."
cat << 'EOF' > /etc/nginx/sites-available/default
upstream core_backend {
    server 192.212.1.6:80;
    server 192.212.1.7:80;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name abbey.k02.com static.k02.com _;

    location / {
        proxy_pass http://core_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "[+] Testing and restarting Nginx on Abbey..."
nginx -t
service nginx restart || /etc/init.d/nginx restart

# Persistence in /etc/network/interfaces
if ! grep -q "service nginx start" /etc/network/interfaces; then
    sed -i '/iface eth0 inet static/a \    up service nginx start' /etc/network/interfaces
fi

# Persistence in /root/init.sh
if [ -f /root/init.sh ] && ! grep -q "service nginx start" /root/init.sh; then
    echo "service nginx start" >> /root/init.sh
fi

echo "[+] Abbey Reverse Proxy setup complete!"

