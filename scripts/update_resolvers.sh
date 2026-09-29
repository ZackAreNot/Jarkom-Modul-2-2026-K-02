#!/bin/bash
# ==============================================================================
# update_resolvers.sh — Updates resolver order on non-router hosts
# Order: prab (192.212.1.2) -> tedd (192.212.1.3) -> 192.168.122.1
# ==============================================================================

cat << 'EOF' > /etc/resolv.conf
nameserver 192.212.1.2
nameserver 192.212.1.3
nameserver 192.168.122.1
EOF

# Update /etc/network/interfaces for reboot persistence
if [ -f /etc/network/interfaces ]; then
    sed -i '/up echo .* > \/etc\/resolv.conf/d' /etc/network/interfaces
    sed -i '/iface eth0 inet static/a \    up echo -e "nameserver 192.212.1.2\\nnameserver 192.212.1.3\\nnameserver 192.168.122.1" > /etc/resolv.conf' /etc/network/interfaces
fi

echo "[+] Resolver successfully updated on $(hostname)!"
