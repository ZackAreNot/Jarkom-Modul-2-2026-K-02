#!/bin/bash
# ==============================================================================
# /root/init.sh - Universal Node Initialization & Recovery Script
# Praktikum Jarkom Modul 2 - Kelompok K-02 (Prefix: 192.212.x.x, Domain: k02.com)
#
# Fungsi:
# 1. Konfigurasi otomatis IP address, default gateway, dan hostname
# 2. Pemulihan /etc/resolv.conf saat node di-restart
# 3. Pemulihan otomatis service penting (BIND9, Apache2, Nginx, PHP-FPM, NAT)
#
# Penggunaan:
#   bash /root/init.sh [node_name]
#   (Jika tanpa argumen, otomatis mendeteksi dari $(hostname))
# ==============================================================================

NODE_NAME="${1:-$(hostname)}"
NODE_LOWER=$(echo "$NODE_NAME" | tr '[:upper:]' '[:lower:]')

# Helper: Set resolver non-router (prab -> tedd -> 192.168.122.1)
set_client_resolver() {
    cat << 'EOF' > /etc/resolv.conf
nameserver 192.212.1.2
nameserver 192.212.1.3
nameserver 192.168.122.1
EOF
}

# Helper: Set DNS gateway awal
set_gateway_resolver() {
    echo "nameserver 192.168.122.1" > /etc/resolv.conf
}

# Pastikan hostname system-wide
echo "$NODE_LOWER" > /etc/hostname 2>/dev/null || true
hostname "$NODE_LOWER" 2>/dev/null || true

case "$NODE_LOWER" in
    *rootkit*|*router*)
        echo "=== [rootkit] Mengonfigurasi Central Router ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
    post-up iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    post-up sysctl -w net.ipv4.ip_forward=1

auto eth1
iface eth1 inet static
    address 192.212.1.1
    netmask 255.255.255.0

auto eth2
iface eth2 inet static
    address 192.212.2.1
    netmask 255.255.255.0

auto eth3
iface eth3 inet static
    address 192.212.3.1
    netmask 255.255.255.0

auto eth4
iface eth4 inet static
    address 192.212.4.1
    netmask 255.255.255.0

auto eth5
iface eth5 inet static
    address 192.212.5.1
    netmask 255.255.255.0
EOF

        # Terapkan IP statis
        ip addr replace 192.212.1.1/24 dev eth1 2>/dev/null || true
        ip addr replace 192.212.2.1/24 dev eth2 2>/dev/null || true
        ip addr replace 192.212.3.1/24 dev eth3 2>/dev/null || true
        ip addr replace 192.212.4.1/24 dev eth4 2>/dev/null || true
        ip addr replace 192.212.5.1/24 dev eth5 2>/dev/null || true

        for i in 0 1 2 3 4 5; do
            ip link set eth$i up 2>/dev/null || true
        done

        # DHCP eth0
        cat << 'EOF' > /etc/udhcpc.script
#!/bin/sh
[ "$1" = "bound" ] || [ "$1" = "renew" ] || exit 0
ip addr replace $ip/$mask dev $interface 2>/dev/null || true
[ -n "$router" ] && ip route replace default via $router dev $interface 2>/dev/null || true
[ -n "$dns" ] && echo "nameserver $dns" > /etc/resolv.conf
EOF
        chmod +x /etc/udhcpc.script
        ln -sf /tmp/gns3/bin/busybox /bin/udhcpc 2>/dev/null || true
        ln -sf /tmp/gns3/bin/busybox /sbin/udhcpc 2>/dev/null || true
        udhcpc -i eth0 -s /etc/udhcpc.script -n -q 2>/dev/null || true

        # NAT & Forwarding
        sysctl -w net.ipv4.ip_forward=1 >/dev/null 2>&1 || true
        iptables -t nat -C POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null || true
        set_gateway_resolver
        echo "[OK] rootkit siap!"
        ;;

    *prab*)
        echo "=== [prab] Mengonfigurasi DNS Master (192.212.1.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.2
    netmask 255.255.255.0
    gateway 192.212.1.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
    up /usr/sbin/named -u bind || true
EOF
        ip addr replace 192.212.1.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        # Pulihkan / jalankan BIND9
        if [ -f /root/setup_prab.sh ]; then
            echo "[*] Menjalankan BIND9 Master via setup_prab.sh..."
            bash /root/setup_prab.sh || true
        else
            pkill -9 named 2>/dev/null || true
            sleep 1
            /usr/sbin/named -u bind 2>/dev/null || true
        fi
        echo "[OK] prab siap!"
        ;;

    *tedd*)
        echo "=== [tedd] Mengonfigurasi DNS Slave (192.212.1.3) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.3
    netmask 255.255.255.0
    gateway 192.212.1.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
    up /usr/sbin/named -u bind || true
EOF
        ip addr replace 192.212.1.3/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        set_gateway_resolver

        # Pulihkan / jalankan BIND9
        if [ -f /root/setup_tedd.sh ]; then
            echo "[*] Menjalankan BIND9 Slave via setup_tedd.sh..."
            bash /root/setup_tedd.sh || true
        else
            pkill -9 named 2>/dev/null || true
            sleep 1
            /usr/sbin/named -u bind 2>/dev/null || true
        fi
        echo "[OK] tedd siap!"
        ;;

    *obladi*)
        echo "=== [obladi] Mengonfigurasi Area Vault 1 (192.212.1.4) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.4
    netmask 255.255.255.0
    gateway 192.212.1.1
    up service apache2 start || true
EOF
        ip addr replace 192.212.1.4/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        set_client_resolver

        if [ ! -d /var/www/html/arsip ] && [ -f /root/setup_vault.sh ]; then
            bash /root/setup_vault.sh || true
        else
            service apache2 restart 2>/dev/null || true
        fi
        echo "[OK] obladi siap!"
        ;;

    *desmond*)
        echo "=== [desmond] Mengonfigurasi Area Vault 2 (192.212.1.5) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.5
    netmask 255.255.255.0
    gateway 192.212.1.1
    up service apache2 start || true
EOF
        ip addr replace 192.212.1.5/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        set_client_resolver

        if [ ! -d /var/www/html/arsip ] && [ -f /root/setup_vault.sh ]; then
            bash /root/setup_vault.sh || true
        else
            service apache2 restart 2>/dev/null || true
        fi
        echo "[OK] desmond siap!"
        ;;

    *oblada*)
        echo "=== [oblada] Mengonfigurasi Area Core 1 (192.212.1.6) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.6
    netmask 255.255.255.0
    gateway 192.212.1.1
    up service php8.4-fpm start || true
    up service apache2 start || true
EOF
        ip addr replace 192.212.1.6/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        set_client_resolver

        if [ ! -f /var/www/html/profil.php ] && [ -f /root/setup_core.sh ]; then
            bash /root/setup_core.sh || true
        else
            service php8.4-fpm restart 2>/dev/null || true
            service apache2 restart 2>/dev/null || true
        fi
        echo "[OK] oblada siap!"
        ;;

    *molly*)
        echo "=== [molly] Mengonfigurasi Area Core 2 (192.212.1.7) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.7
    netmask 255.255.255.0
    gateway 192.212.1.1
    up service php8.4-fpm start || true
    up service apache2 start || true
EOF
        ip addr replace 192.212.1.7/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        set_client_resolver

        if [ ! -f /var/www/html/profil.php ] && [ -f /root/setup_core.sh ]; then
            bash /root/setup_core.sh || true
        else
            service php8.4-fpm restart 2>/dev/null || true
            service apache2 restart 2>/dev/null || true
        fi
        echo "[OK] molly siap!"
        ;;

    *alpha*)
        echo "=== [alpha] Mengonfigurasi Klien Sayap Kiri (192.212.2.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.2.2
    netmask 255.255.255.0
    gateway 192.212.2.1
EOF
        ip addr replace 192.212.2.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.2.1 dev eth0 2>/dev/null || true
        set_client_resolver
        echo "[OK] alpha siap!"
        ;;

    *beta*)
        echo "=== [beta] Mengonfigurasi Klien Sayap Kiri (192.212.2.3) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.2.3
    netmask 255.255.255.0
    gateway 192.212.2.1
EOF
        ip addr replace 192.212.2.3/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.2.1 dev eth0 2>/dev/null || true
        set_client_resolver
        echo "[OK] beta siap!"
        ;;

    *gamma*)
        echo "=== [gamma] Mengonfigurasi Klien Sayap Kiri (192.212.2.4) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.2.4
    netmask 255.255.255.0
    gateway 192.212.2.1
EOF
        ip addr replace 192.212.2.4/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.2.1 dev eth0 2>/dev/null || true
        set_client_resolver
        echo "[OK] gamma siap!"
        ;;

    *delta*)
        echo "=== [delta] Mengonfigurasi Klien Sayap Kanan (192.212.3.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.3.2
    netmask 255.255.255.0
    gateway 192.212.3.1
EOF
        ip addr replace 192.212.3.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.3.1 dev eth0 2>/dev/null || true
        set_client_resolver
        echo "[OK] delta siap!"
        ;;

    *epsilon*)
        echo "=== [epsilon] Mengonfigurasi Klien Sayap Kanan (192.212.3.3) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.3.3
    netmask 255.255.255.0
    gateway 192.212.3.1
EOF
        ip addr replace 192.212.3.3/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.3.1 dev eth0 2>/dev/null || true
        set_client_resolver
        echo "[OK] epsilon siap!"
        ;;

    *abbey*)
        echo "=== [abbey] Mengonfigurasi Gerbang Nginx (192.212.4.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.2
    netmask 255.255.255.0
    gateway 192.212.4.1
    up service nginx start || true
EOF
        ip addr replace 192.212.4.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        set_client_resolver

        if [ ! -f /etc/nginx/sites-available/default ] && [ -f /root/setup_proxy.sh ]; then
            bash /root/setup_proxy.sh || true
        else
            service nginx restart 2>/dev/null || true
        fi
        echo "[OK] abbey siap!"
        ;;

    *penny*)
        echo "=== [penny] Mengonfigurasi Gerbang Apache (192.212.5.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.5.2
    netmask 255.255.255.0
    gateway 192.212.5.1
    up service apache2 start || true
EOF
        ip addr replace 192.212.5.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.5.1 dev eth0 2>/dev/null || true
        set_client_resolver

        if [ ! -f /etc/apache2/sites-available/000-default.conf ] && [ -f /root/setup_proxy.sh ]; then
            bash /root/setup_proxy.sh || true
        else
            service apache2 restart 2>/dev/null || true
        fi
        echo "[OK] penny siap!"
        ;;

    *)
        echo "Error: Node '$NODE_NAME' tidak dikenali!"
        echo "Penggunaan: bash /root/init.sh [rootkit|prab|tedd|obladi|desmond|oblada|molly|alpha|beta|gamma|delta|epsilon|abbey|penny]"
        exit 1
        ;;
esac
