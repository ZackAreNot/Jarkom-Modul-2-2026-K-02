#!/bin/bash
# ==============================================================================
# Setup Reverse Proxy Apache2 pada Node Penny (Subnet 5)
# Mengarah ke Area Vault: Obladi (192.212.1.4) & Desmond (192.212.1.5)
# Load balancing: Round-robin (byrequests)
# Header forwarding: Host & X-Real-IP
# ==============================================================================
set -e

echo "[+] Updating apt and installing apache2 on Penny..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2

echo "[+] Enabling required Apache proxy & header modules..."
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers rewrite

echo "[+] Configuring Apache Reverse Proxy for Area Vault on Penny..."
cat << 'EOF' > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:80>
    ServerName penny.k02.com
    ServerAlias www.k02.com k02.com
    ServerAdmin webmaster@k02.com

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
service apache2 restart || apache2ctl restart

# Persistence in /etc/network/interfaces
if ! grep -q "service apache2 start" /etc/network/interfaces; then
    sed -i '/iface eth0 inet static/a \    up service apache2 start' /etc/network/interfaces
fi

# Persistence in /root/init.sh
if [ -f /root/init.sh ] && ! grep -q "service apache2 start" /root/init.sh; then
    echo "service apache2 start" >> /root/init.sh
fi

echo "[+] Penny Reverse Proxy setup complete!"

