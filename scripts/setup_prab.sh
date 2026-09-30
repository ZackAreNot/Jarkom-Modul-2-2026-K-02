#!/bin/bash
# ==============================================================================
# setup_prab.sh — Authoritative DNS Master (NS1) for k02.com & Reverse Zones
# Praktikum Modul 2 Jarkom 2026 - Kelompok K-02
# ==============================================================================

set -e

echo "[*] Ensuring BIND9 packages are installed on prab..."
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

echo "[*] Configuring /etc/bind/named.conf.local with Forward & Reverse Zones..."
cat << 'EOF' > /etc/bind/named.conf.local
zone "k02.com" {
    type master;
    file "/etc/bind/k02/db.k02.com";
    notify yes;
    also-notify { 192.212.1.3; };
    allow-transfer { 192.212.1.3; };
};

zone "1.212.192.in-addr.arpa" {
    type master;
    file "/etc/bind/k02/db.192.212.1";
    notify yes;
    also-notify { 192.212.1.3; };
    allow-transfer { 192.212.1.3; };
};

zone "4.212.192.in-addr.arpa" {
    type master;
    file "/etc/bind/k02/db.192.212.4";
    notify yes;
    also-notify { 192.212.1.3; };
    allow-transfer { 192.212.1.3; };
};

zone "5.212.192.in-addr.arpa" {
    type master;
    file "/etc/bind/k02/db.192.212.5";
    notify yes;
    also-notify { 192.212.1.3; };
    allow-transfer { 192.212.1.3; };
};
EOF

mkdir -p /etc/bind/k02

echo "[*] Creating Forward Zone /etc/bind/k02/db.k02.com..."
cat << 'EOF' > /etc/bind/k02/db.k02.com
$TTL    604800
@       IN      SOA     prab.k02.com. root.k02.com. (
                              2026092803         ; Serial
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
rootkit IN      A       192.212.1.1
alpha   IN      A       192.212.2.2
beta    IN      A       192.212.2.3
gamma   IN      A       192.212.2.4
delta   IN      A       192.212.3.2
epsilon IN      A       192.212.3.3
abbey   IN      A       192.212.4.2
penny   IN      A       192.212.5.2
obladi  IN      A       192.212.1.4
desmond IN      A       192.212.1.5
oblada  IN      A       192.212.1.6
molly   IN      A       192.212.1.7

; Round-robin Vault & Core
vault   IN      A       192.212.1.4
vault   IN      A       192.212.1.5
core    IN      A       192.212.1.6
core    IN      A       192.212.1.7

; CNAME Records
www     IN      CNAME   penny.k02.com.
static  IN      CNAME   abbey.k02.com.
EOF

echo "[*] Creating Reverse Zone Subnet 1 (db.192.212.1)..."
cat << 'EOF' > /etc/bind/k02/db.192.212.1
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

1       IN      PTR     rootkit.k02.com.
2       IN      PTR     prab.k02.com.
3       IN      PTR     tedd.k02.com.
4       IN      PTR     obladi.k02.com.
5       IN      PTR     desmond.k02.com.
6       IN      PTR     oblada.k02.com.
7       IN      PTR     molly.k02.com.
EOF

echo "[*] Creating Reverse Zone Subnet 4 (db.192.212.4)..."
cat << 'EOF' > /etc/bind/k02/db.192.212.4
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

1       IN      PTR     rootkit.k02.com.
2       IN      PTR     abbey.k02.com.
EOF

echo "[*] Creating Reverse Zone Subnet 5 (db.192.212.5)..."
cat << 'EOF' > /etc/bind/k02/db.192.212.5
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

1       IN      PTR     rootkit.k02.com.
2       IN      PTR     penny.k02.com.
EOF

echo "[*] Checking BIND9 configuration syntax..."
named-checkconf
named-checkzone k02.com /etc/bind/k02/db.k02.com
named-checkzone 1.212.192.in-addr.arpa /etc/bind/k02/db.192.212.1
named-checkzone 4.212.192.in-addr.arpa /etc/bind/k02/db.192.212.4
named-checkzone 5.212.192.in-addr.arpa /etc/bind/k02/db.192.212.5

echo "[*] Restarting clean BIND9..."
pkill -9 named 2>/dev/null || true
sleep 1
/usr/sbin/named -u bind || service named start || service bind9 start

echo "[+] BIND9 Master on prab successfully configured with Forward & Reverse zones!"
