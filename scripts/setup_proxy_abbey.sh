#!/bin/bash
# ==============================================================================
# Setup Reverse Proxy Nginx pada Node Abbey (Subnet 4)
# Soal 11: Reverse Proxy Area Core: Oblada (192.212.1.6) & Molly (192.212.1.7)
# Soal 13: Redirect Sementara (302) IP abbey & abbey.k02.com ke static.k02.com
# Soal 15: Jalur Khusus /orion -> /var/www/orion (Murni Statis Tanpa PHP)
# ==============================================================================
set -e

echo "[+] Updating apt and installing Nginx on Abbey..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

# Soal 15: Direktori /var/www/orion statis murni
mkdir -p /var/www/orion
cat << 'EOF' > /var/www/orion/index.html
<!DOCTYPE html>
<html>
<head><title>Jalur Orion</title></head>
<body>
    <h1>JALUR KHUSUS ORION (ABBEY)</h1>
    <p>Status: <strong>Murni Statis (Tanpa PHP Rendering)</strong></p>
    <p>Dokumen ini disajikan langsung oleh Nginx sebagai file statis murni.</p>
</body>
</html>
EOF

# File pengujian PHP mentah (membuktikan Nginx tidak merender PHP)
cat << 'EOF' > /var/www/orion/test.php
<?php echo "Ini kode mentah PHP, tidak dieksekusi."; ?>
EOF
chown -R www-data:www-data /var/www/orion

echo "[+] Configuring Nginx Reverse Proxy, 302 Redirect & /orion on Abbey..."
cat << 'EOF' > /etc/nginx/sites-available/default
upstream core_backend {
    server 192.212.1.6:80;
    server 192.212.1.7:80;
}

# Soal 13: Redirect Sementara (302) ke static.k02.com
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name abbey.k02.com 192.212.4.2 _;

    return 302 http://static.k02.com$request_uri;
}

# Host Kanonik static.k02.com
server {
    listen 80;
    listen [::]:80;
    server_name static.k02.com;

    # Soal 15: Jalur khusus /orion statis murni
    location /orion {
        alias /var/www/orion;
        index index.html;
        try_files $uri $uri/ /orion/index.html =404;
    }

    # Soal 11: Reverse Proxy ke Area Core
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

echo "[+] Abbey setup complete!"
