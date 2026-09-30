#!/bin/bash
# ==============================================================================
# setup_tedd.sh — Authoritative DNS Slave (NS2) for k02.com & Reverse Zones
# Praktikum Modul 2 Jarkom 2026 - Kelompok K-02
# ==============================================================================

set -e

echo "[*] Ensuring BIND9 packages are installed on tedd..."
which named >/dev/null 2>&1 || {
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils dnsutils
}

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

echo "[*] Configuring /etc/bind/named.conf.local with Forward & Reverse Slave Zones..."
cat << 'EOF' > /etc/bind/named.conf.local
zone "k02.com" {
    type slave;
    file "/var/cache/bind/db.k02.com";
    masters { 192.212.1.2; };
};

zone "1.212.192.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.192.212.1";
    masters { 192.212.1.2; };
};

zone "4.212.192.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.192.212.4";
    masters { 192.212.1.2; };
};

zone "5.212.192.in-addr.arpa" {
    type slave;
    file "/var/cache/bind/db.192.212.5";
    masters { 192.212.1.2; };
};
EOF

echo "[*] Checking configuration syntax..."
named-checkconf

echo "[*] Restarting clean BIND9..."
pkill -9 named 2>/dev/null || true
sleep 1
/usr/sbin/named -u bind || service named start || service bind9 start

echo "[*] Retransferring zones from prab (192.212.1.2)..."
sleep 1
rndc retransfer k02.com 2>/dev/null || true
rndc retransfer 1.212.192.in-addr.arpa 2>/dev/null || true
rndc retransfer 4.212.192.in-addr.arpa 2>/dev/null || true
rndc retransfer 5.212.192.in-addr.arpa 2>/dev/null || true

echo "[+] BIND9 Slave on tedd successfully configured and synchronized!"
