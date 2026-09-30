#!/bin/bash
# ==============================================================================
# Setup Reverse Proxy Apache2 pada Node Penny (Subnet 5)
# Soal 11: Reverse Proxy Area Vault + Load Balancing + Header Forwarding
# Soal 12: Basic Authentication untuk path /admin (prabs : pakar_pinter_jadi_goblok)
# Soal 13: Redirect Permanen (301) IP penny & penny.k02.com ke www.k02.com
# Soal 15: Jalur Khusus /eternal -> /var/www/eternal (Eksekusi PHP Dinamis)
# ==============================================================================
set -e

echo "[+] Updating apt and installing apache2, utils & php-fpm on Penny..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apache2-utils php8.4-fpm php8.4-cli || DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 apache2-utils php-fpm php-cli

echo "[+] Enabling required Apache proxy, auth, fpm & rewrite modules..."
a2enmod proxy proxy_http proxy_balancer proxy_fcgi lbmethod_byrequests headers rewrite auth_basic authn_file authz_user setenvif

# Start PHP-FPM service
service php8.4-fpm restart 2>/dev/null || service php-fpm restart 2>/dev/null || /etc/init.d/php8.4-fpm restart 2>/dev/null || true

# Soal 12: Direktori rahasia /admin
mkdir -p /var/www/html/admin
cat << 'EOF' > /var/www/html/admin/index.html
<!DOCTYPE html>
<html>
<head><title>Admin Syndicate</title></head>
<body>
    <h1>DOKUMEN RAHASIA SINDIKAT THE MESH</h1>
    <p>Akses berhasil diverifikasi untuk agen prabs.</p>
</body>
</html>
EOF

htpasswd -bc /etc/apache2/.htpasswd prabs pakar_pinter_jadi_goblok

# Soal 15: Direktori khusus /var/www/eternal dengan PHP
mkdir -p /var/www/eternal
cat << 'EOF' > /var/www/eternal/index.php
<!DOCTYPE html>
<html>
<head><title>Jalur Eternal</title></head>
<body>
    <h1>JALUR KHUSUS ETERNAL (PENNY)</h1>
    <p>Status: <strong>PHP Rendering Aktif</strong></p>
    <p>PHP Version: <strong><?php echo phpversion(); ?></strong></p>
    <p>Waktu Server: <strong><?php echo date('Y-m-d H:i:s'); ?></strong></p>
    <p>Hasil Eksekusi Fungsi Dinamis 5 x 5 = <strong><?php echo (5 * 5); ?></strong></p>
</body>
</html>
EOF
chown -R www-data:www-data /var/www/eternal

echo "[+] Configuring Apache VirtualHost with /admin, /eternal & Load Balancer..."
cat << 'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName www.k02.com
    ServerAlias penny.k02.com 192.212.5.2 k02.com
    ServerAdmin webmaster@k02.com

    # Soal 13: Redirect Permanen (301) ke nama kanonik www.k02.com (kecuali admin & eternal)
    RewriteEngine On
    RewriteCond %{REQUEST_URI} !^/(admin|eternal)
    RewriteCond %{HTTP_HOST} ^penny\.k02\.com$ [NC,OR]
    RewriteCond %{HTTP_HOST} ^192\.212\.5\.2$ [NC]
    RewriteRule ^(.*)$ http://www.k02.com$1 [R=301,L]

    # Soal 15: Jalur Khusus /eternal -> /var/www/eternal dengan eksekusi PHP
    ProxyPass /eternal !
    Alias /eternal /var/www/eternal
    <Directory /var/www/eternal>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
        DirectoryIndex index.php index.html

        <FilesMatch \.php$>
            SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
        </FilesMatch>
    </Directory>

    # Soal 12: Basic Authentication untuk path /admin
    ProxyPass /admin !
    Alias /admin /var/www/html/admin
    <Directory /var/www/html/admin>
        AuthType Basic
        AuthName "Restricted Syndicate Admin Area"
        AuthUserFile /etc/apache2/.htpasswd
        Require user prabs
        Options Indexes FollowSymLinks
        AllowOverride None
    </Directory>

    # Soal 11: Cluster Balancer ke Area Vault (Obladi & Desmond)
    <Proxy balancer://vaultcluster>
        BalancerMember http://192.212.1.4:80
        BalancerMember http://192.212.1.5:80
        ProxySet lbmethod=byrequests
    </Proxy>

    ProxyPreserveHost On
    RequestHeader set X-Real-IP "expr=%{REMOTE_ADDR}"

    ProxyPass / balancer://vaultcluster/
    ProxyPassReverse / balancer://vaultcluster/

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

echo "[+] Testing and restarting Apache on Penny..."
apache2ctl configtest
service php8.4-fpm restart 2>/dev/null || true
service apache2 restart || apache2ctl restart

# Persistence in /etc/network/interfaces
if ! grep -q "service apache2 start" /etc/network/interfaces; then
    sed -i '/iface eth0 inet static/a \    up service php8.4-fpm start\n    up service apache2 start' /etc/network/interfaces
fi

echo "[+] Penny setup complete!"
