#!/bin/bash
# =======================================================
# /root/init.sh - Universal Interface Setup Script (Soal 1)
# Jarkom Modul 2 - Kelompok K-02 (Prefix: 192.212.x.x)
#
# Penggunaan: bash /root/init.sh [node_name]
# Jika tanpa argumen, otomatis mendeteksi dari $(hostname)
# =======================================================

NODE_NAME="${1:-$(hostname)}"
NODE_LOWER=$(echo "$NODE_NAME" | tr '[:upper:]' '[:lower:]')

case "$NODE_LOWER" in
    *rootkit*|*router*)
        echo "=== [rootkit] Mengonfigurasi Central Router ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp

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

        # Terapkan alamat IP statis pada seluruh interface LAN internal
        ip addr replace 192.212.1.1/24 dev eth1 2>/dev/null || true
        ip addr replace 192.212.2.1/24 dev eth2 2>/dev/null || true
        ip addr replace 192.212.3.1/24 dev eth3 2>/dev/null || true
        ip addr replace 192.212.4.1/24 dev eth4 2>/dev/null || true
        ip addr replace 192.212.5.1/24 dev eth5 2>/dev/null || true

        # Pastikan interface UP
        for i in 0 1 2 3 4 5; do
            ip link set eth$i up 2>/dev/null || true
        done

        # Setup DHCP script untuk eth0 (NAT)
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

        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] rootkit berhasil dikonfigurasi!"
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
EOF
        ip addr replace 192.212.1.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] prab berhasil dikonfigurasi!"
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
EOF
        ip addr replace 192.212.1.3/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] tedd berhasil dikonfigurasi!"
        ;;

    *obladi*)
        echo "=== [obladi] Mengonfigurasi Vault Web Statis (192.212.1.4) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.4
    netmask 255.255.255.0
    gateway 192.212.1.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.1.4/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] obladi berhasil dikonfigurasi!"
        ;;

    *desmond*)
        echo "=== [desmond] Mengonfigurasi Vault Web Statis (192.212.1.5) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.5
    netmask 255.255.255.0
    gateway 192.212.1.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.1.5/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] desmond berhasil dikonfigurasi!"
        ;;

    *oblada*)
        echo "=== [oblada] Mengonfigurasi Core Web Dinamis (192.212.1.6) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.6
    netmask 255.255.255.0
    gateway 192.212.1.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.1.6/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] oblada berhasil dikonfigurasi!"
        ;;

    *molly*)
        echo "=== [molly] Mengonfigurasi Core Web Dinamis (192.212.1.7) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.1.7
    netmask 255.255.255.0
    gateway 192.212.1.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.1.7/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.1.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] molly berhasil dikonfigurasi!"
        ;;

    *alpha*)
        echo "=== [alpha] Mengonfigurasi Klien Sayap Kiri (192.212.2.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.2.2
    netmask 255.255.255.0
    gateway 192.212.2.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.2.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.2.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] alpha berhasil dikonfigurasi!"
        ;;

    *beta*)
        echo "=== [beta] Mengonfigurasi Klien Sayap Kiri (192.212.2.3) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.2.3
    netmask 255.255.255.0
    gateway 192.212.2.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.2.3/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.2.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] beta berhasil dikonfigurasi!"
        ;;

    *gamma*)
        echo "=== [gamma] Mengonfigurasi Klien Sayap Kiri (192.212.2.4) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.2.4
    netmask 255.255.255.0
    gateway 192.212.2.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.2.4/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.2.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] gamma berhasil dikonfigurasi!"
        ;;

    *delta*)
        echo "=== [delta] Mengonfigurasi Klien Sayap Kanan (192.212.3.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.3.2
    netmask 255.255.255.0
    gateway 192.212.3.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.3.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.3.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] delta berhasil dikonfigurasi!"
        ;;

    *epsilon*)
        echo "=== [epsilon] Mengonfigurasi Klien Sayap Kanan (192.212.3.3) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.3.3
    netmask 255.255.255.0
    gateway 192.212.3.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.3.3/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.3.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] epsilon berhasil dikonfigurasi!"
        ;;

    *abbey*)
        echo "=== [abbey] Mengonfigurasi Gerbang Nginx (192.212.4.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.4.2
    netmask 255.255.255.0
    gateway 192.212.4.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.4.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.4.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] abbey berhasil dikonfigurasi!"
        ;;

    *penny*)
        echo "=== [penny] Mengonfigurasi Gerbang Apache (192.212.5.2) ==="
        cat << 'EOF' > /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.212.5.2
    netmask 255.255.255.0
    gateway 192.212.5.1
    up echo "nameserver 192.168.122.1" > /etc/resolv.conf
EOF
        ip addr replace 192.212.5.2/24 dev eth0 2>/dev/null || true
        ip route replace default via 192.212.5.1 dev eth0 2>/dev/null || true
        echo "nameserver 192.168.122.1" > /etc/resolv.conf
        echo "[OK] penny berhasil dikonfigurasi!"
        ;;

    *)
        echo "Error: Node '$NODE_NAME' tidak dikenali!"
        echo "Penggunaan: bash /root/init.sh [rootkit|prab|tedd|obladi|desmond|oblada|molly|alpha|beta|gamma|delta|epsilon|abbey|penny]"
        exit 1
        ;;
esac
