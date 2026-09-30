#!/bin/bash
# ==============================================================================
# setup_prab.sh — Authoritative DNS Master (NS1) for k02.com
# Praktikum Modul 2 Jarkom 2026 - Kelompok K-02
# ==============================================================================

set -e

echo "[*] Updating package list & installing BIND9 on prab..."
apt-get update -y
apt-get install -y bind9 bind9utils bind9-doc dnsutils

echo "[*] Configuring /etc/bind/named.conf.options..."
cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";

    forwarders {
        192.168.122.1;
    };

    allow-query { any; };
    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
};
EOF

echo "[*] Configuring /etc/bind/named.conf.local..."
cat << 'EOF' > /etc/bind/named.conf.local
zone "k02.com" {
    type master;
    file "/etc/bind/k02/db.k02.com";
    notify yes;
    also-notify { 192.212.1.3; };
    allow-transfer { 192.212.1.3; };
};
EOF

echo "[*] Creating zone directory and file /etc/bind/k02/db.k02.com..."
mkdir -p /etc/bind/k02
cat << 'EOF' > /etc/bind/k02/db.k02.com
$TTL    604800
@       IN      SOA     prab.k02.com. root.k02.com. (
                              2026092801         ; Serial
                                  604800         ; Refresh
                                   86400         ; Retry
                                 2419200         ; Expire
                                  604800 )       ; Negative Cache TTL
;
@       IN      NS      prab.k02.com.
@       IN      NS      tedd.k02.com.

@       IN      A       192.212.5.2
prab    IN      A       192.212.1.2
tedd    IN      A       192.212.1.3
EOF

echo "[*] Checking configuration syntax..."
named-checkconf
named-checkzone k02.com /etc/bind/k02/db.k02.com

echo "[*] Restarting BIND9 (named) service..."
service named restart || service bind9 restart

# Ensure BIND9 service starts on boot
if ! grep -q "service named start" /etc/network/interfaces; then
    sed -i '/iface eth0 inet static/a \    up service named start' /etc/network/interfaces
fi

echo "[+] BIND9 Master on prab successfully configured and running!"
