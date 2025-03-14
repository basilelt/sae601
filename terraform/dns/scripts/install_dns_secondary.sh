#!/bin/bash

# This script configures the secondary DNS server for the zone
# Usage: DNS_PRIMARY_IP=10.x.x.x bash install_dns_secondary.sh

set -e
echo "Starting secondary DNS server installation script..."

# Get the primary DNS server IP if passed as environment variable
DNS_PRIMARY_IP=${DNS_PRIMARY_IP:-"10.129.4.249"}

# 1. Update system and install prerequisites
apt-get update && apt-get upgrade -y

# 2. Install and Configure BIND9 DNS Server
echo "Installing BIND9 DNS Server..."
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9utils bind9-doc

# Configure BIND9 options
cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    forwarders {
        10.9.0.241;
        10.9.0.240;
        10.129.4.241;
    };

    allow-query { any; };
    allow-recursion { any; };
    recursion yes;
    dnssec-validation no;
    listen-on { any; };
};
EOF

# Configure zones for secondary
cat > /etc/bind/named.conf.local << EOF
zone "basile.uha.fr" {
    type slave;
    file "db.basile.uha.fr";
    masters { ${DNS_PRIMARY_IP}; };
};

zone "4.129.10.in-addr.arpa" {
    type slave;
    file "db.10.129.4";
    masters { ${DNS_PRIMARY_IP}; };
};

zone "5.129.10.in-addr.arpa" {
    type slave;
    file "db.10.129.5";
    masters { ${DNS_PRIMARY_IP}; };
};
EOF

# Set permissions for BIND9 to write zone transfers
chown -R bind:bind /var/cache/bind

# Validate configuration
named-checkconf

# Restart and enable BIND9
systemctl restart named
systemctl enable named
echo "Secondary DNS Server configured with primary at ${DNS_PRIMARY_IP}"

# Use our own DNS server
echo "nameserver 127.0.0.1" > /etc/resolv.conf

# Wait a bit for zone transfer to complete
sleep 10

echo "================================================================"
echo "Secondary DNS server configured for basile.uha.fr domain"
echo "Primary DNS server is at ${DNS_PRIMARY_IP}"
echo "================================================================"
