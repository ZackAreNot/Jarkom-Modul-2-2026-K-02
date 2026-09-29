#!/bin/bash
# ==============================================================================
# Setup Web Server Dinamis (Nginx + PHP8.4-FPM) & URL Rewrite /profil pada Molly
# Node: molly (192.212.1.7) - Area Core 2
# Domain: molly.k02.com / core.k02.com
# ==============================================================================
set -e

echo "[+] Updating apt and installing nginx and php8.4-fpm..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php8.4-fpm php8.4-cli

echo "[+] Setting up web root directory..."
mkdir -p /var/www/html
rm -f /var/www/html/index.nginx-debian.html

# 1. Halaman Beranda (index.php)
cat << 'EOF' > /var/www/html/index.php
<?php
$hostname = gethostname();
$server_ip = $_SERVER['SERVER_ADDR'] ?? '192.212.1.7';
?>
<!DOCTYPE html>
<html>
<head>
    <title>Area Core - Home (<?php echo $hostname; ?>)</title>
</head>
<body>
    <h1>Selamat Datang di Area Core - The Mesh</h1>
    <p>Node Hostname: <strong><?php echo $hostname; ?>.k02.com</strong></p>
    <p>Server IP: <strong><?php echo $server_ip; ?></strong></p>
    <p>PHP Version: <strong><?php echo phpversion(); ?></strong></p>
    <p>Web Server: <strong>Nginx + PHP8.4-FPM</strong></p>
    <hr>
    <p>Tautan: <a href="/profil">Halaman Profil (/profil)</a></p>
</body>
</html>
EOF

# 2. Halaman Profil (profil.php)
cat << 'EOF' > /var/www/html/profil.php
<?php
$hostname = gethostname();
$server_ip = $_SERVER['SERVER_ADDR'] ?? '192.212.1.7';
?>
<!DOCTYPE html>
<html>
<head>
    <title>Area Core - Profil (<?php echo $hostname; ?>)</title>
</head>
<body>
    <h1>Profil Entitas Area Core</h1>
    <p>Identitas: <strong><?php echo strtoupper($hostname); ?></strong></p>
    <p>Divisi: <strong>Area Core (Repositori Web Dinamis The Mesh)</strong></p>
    <p>Domain Kanonik: <strong><?php echo $hostname; ?>.k02.com</strong></p>
    <p>Kluster Domain: <strong>core.k02.com</strong></p>
    <p>Server IP: <strong><?php echo $server_ip; ?></strong></p>
    <p>PHP-FPM Engine: <strong>PHP <?php echo phpversion(); ?> (php8.4-fpm)</strong></p>
    <p>Status Rewrite: <strong>Clean URL Aktif (/profil -> profil.php)</strong></p>
    <hr>
    <p>Tautan: <a href="/">Kembali ke Beranda (/)</a></p>
</body>
</html>
EOF

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "[+] Configuring Nginx virtual host with URL rewrite for /profil..."
cat << 'EOF' > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name molly.k02.com core.k02.com _;

    root /var/www/html;
    index index.php index.html index.htm;

    # Rewrite rule for clean URL /profil without .php extension
    rewrite ^/profil/?$ /profil.php last;

    location / {
        try_files $uri $uri/ $uri.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

echo "[+] Testing Nginx configuration..."
nginx -t

echo "[+] Starting PHP8.4-FPM and Nginx services..."
service php8.4-fpm restart || /etc/init.d/php8.4-fpm restart
service nginx restart || /etc/init.d/nginx restart

# Persistence in /etc/network/interfaces
if ! grep -q "service php8.4-fpm start" /etc/network/interfaces; then
    sed -i '/iface eth0 inet static/a \    up service php8.4-fpm start\n    up service nginx start' /etc/network/interfaces
fi

# Persistence in /root/init.sh
if [ -f /root/init.sh ]; then
    if ! grep -q "service php8.4-fpm start" /root/init.sh; then
        echo "service php8.4-fpm start" >> /root/init.sh
    fi
    if ! grep -q "service nginx start" /root/init.sh; then
        echo "service nginx start" >> /root/init.sh
    fi
fi

echo "[+] Molly Nginx + PHP8.4-FPM setup complete!"
