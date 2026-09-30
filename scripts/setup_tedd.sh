#!/bin/bash
# ==============================================================================
# setup_tedd.sh — Authoritative DNS Slave (NS2) for k02.com
# Praktikum Modul 2 Jarkom 2026 - Kelompok K-02
# ==============================================================================

set -e

echo "[*] Updating package list & installing BIND9 on tedd..."
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
    type slave;
    file "/var/cache/bind/db.k02.com";
    masters { 192.212.1.2; };
};
EOF

echo "[*] Checking configuration syntax..."
named-checkconf

echo "[*] Restarting BIND9 (named) service..."
service named restart || service bind9 restart

# Ensure BIND9 service starts on boot
if ! grep -q "service named start" /etc/network/interfaces; then
    sed -i '/iface eth0 inet static/a \    up service named start' /etc/network/interfaces
fi

echo "[+] BIND9 Slave on tedd successfully configured and running!"
