#!/bin/bash
# ==============================================================================
# Setup Web Server Statis (Apache2) & Directory Listing /arsip/ pada Obladi
# Node: obladi (192.212.1.4) - Area Vault 1
# Domain: obladi.k02.com / vault.k02.com
# ==============================================================================
set -e

echo "[+] Updating apt and installing apache2..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2

echo "[+] Enabling modules..."
a2enmod autoindex rewrite

echo "[+] Creating /var/www/html/arsip directory..."
mkdir -p /var/www/html/arsip

# Sample files for directory listing autoindex
echo "Ini adalah dokumen rahasia The Mesh pada arsip Obladi (Area Vault 1)." > /var/www/html/arsip/arsip_obladi.txt
echo "Laporan intelijen Shadow Net Operation - Vault Master Record." > /var/www/html/arsip/dokumen_mesh.txt
echo "DUMMY ARCHIVE CONTENT OBLADI" > /var/www/html/arsip/database_vault_backup.tar.gz
echo "CONFIDENTIAL PDF DUMMY" > /var/www/html/arsip/secret_data.pdf

# Remove any default index files to trigger autoindex
rm -f /var/www/html/arsip/index.html /var/www/html/arsip/index.php

chown -R www-data:www-data /var/www/html/arsip
chmod -R 755 /var/www/html/arsip

echo "[+] Configuring Apache directory listing for /arsip/..."
cat << 'EOF' > /etc/apache2/conf-available/arsip.conf
<Directory /var/www/html/arsip>
    Options +Indexes +FollowSymLinks
    IndexOptions FancyIndexing VersionSort NameWidth=* DescriptionWidth=* FoldersFirst
    AllowOverride None
    Require all granted
</Directory>
EOF

a2enconf arsip

# Update VirtualHost with ServerName and ServerAlias
cat << 'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName obladi.k02.com
    ServerAlias vault.k02.com
    ServerAdmin webmaster@k02.com
    DocumentRoot /var/www/html

    <Directory /var/www/html/arsip>
        Options +Indexes +FollowSymLinks
        IndexOptions FancyIndexing VersionSort NameWidth=* DescriptionWidth=* FoldersFirst
        AllowOverride None
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

echo "[+] Starting and enabling Apache2..."
service apache2 restart || apache2ctl restart

# Persistence in /etc/network/interfaces
if ! grep -q "service apache2 start" /etc/network/interfaces; then
    sed -i '/iface eth0 inet static/a \    up service apache2 start' /etc/network/interfaces
fi

# Persistence in /root/init.sh
if [ -f /root/init.sh ] && ! grep -q "service apache2 start" /root/init.sh; then
    echo "service apache2 start" >> /root/init.sh
fi

echo "[+] Obladi Apache2 setup complete!"
