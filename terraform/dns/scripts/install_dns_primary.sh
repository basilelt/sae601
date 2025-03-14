#!/bin/bash

# This script configures the primary DNS server for the zone
# Usage: DNS_SECONDARY_IP=10.x.x.x bash install_dns_primary.sh

set -e
echo "Starting primary DNS server installation script..."

# Get the secondary DNS server IP if passed as environment variable
DNS_SECONDARY_IP=${DNS_SECONDARY_IP:-"10.129.4.249"}

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
    allow-transfer { ${DNS_SECONDARY_IP}; };
    also-notify { ${DNS_SECONDARY_IP}; };
    notify yes;

    recursion yes;
    dnssec-validation no;
    listen-on { any; };
};
EOF

# Configure zones for primary
cat > /etc/bind/named.conf.local << EOF
zone "basile.uha.fr" {
    type master;
    file "/etc/bind/zones/db.basile.uha.fr";
    notify yes;
    allow-transfer { ${DNS_SECONDARY_IP}; };
};

zone "4.129.10.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.10.129.4";
    notify yes;
    allow-transfer { ${DNS_SECONDARY_IP}; };
};

zone "5.129.10.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.10.129.5";
    notify yes;
    allow-transfer { ${DNS_SECONDARY_IP}; };
};
EOF

# Create zone directory
mkdir -p /etc/bind/zones

# Create forward zone file
cat > /etc/bind/zones/db.basile.uha.fr << EOF
\$TTL    604800
@       IN      SOA     ns1.basile.uha.fr. admin.basile.uha.fr. (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.basile.uha.fr.
@       IN      NS      ns2.basile.uha.fr.
ns1     IN      A       $(hostname -I | awk '{print $1}')
ns2     IN      A       ${DNS_SECONDARY_IP}

; Specific entry for kube.basile.uha.fr
kube IN      A       10.129.4.242
kube IN      A       10.129.4.243
kube IN      A       10.129.4.244

; Wildcard for kube subdomain pointing to all masters
*.kube IN      A       10.129.4.242
*.kube IN      A       10.129.4.243
*.kube IN      A       10.129.4.244

; Kubernetes masters
master1 IN      A       10.129.4.242
master2 IN      A       10.129.4.243
master3 IN      A       10.129.4.244

; GitLab server
gitlab  IN      A       10.129.4.241
EOF

# Create reverse zone files
cat > /etc/bind/zones/db.10.129.4 << EOF
\$TTL    604800
@       IN      SOA     ns1.basile.uha.fr. admin.basile.uha.fr. (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.basile.uha.fr.
@       IN      NS      ns2.basile.uha.fr.

; PTR Records
241     IN      PTR     gitlab.basile.uha.fr.
242     IN      PTR     master1.basile.uha.fr.
243     IN      PTR     master2.basile.uha.fr.
244     IN      PTR     master3.basile.uha.fr.
$(echo $(hostname -I | awk '{print $1}') | cut -d. -f4)    IN      PTR     ns1.basile.uha.fr.
$(echo ${DNS_SECONDARY_IP} | cut -d. -f4)    IN      PTR     ns2.basile.uha.fr.
EOF

cat > /etc/bind/zones/db.10.129.5 << EOF
\$TTL    604800
@       IN      SOA     ns1.basile.uha.fr. admin.basile.uha.fr. (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.basile.uha.fr.
@       IN      NS      ns2.basile.uha.fr.

; PTR Records for 10.129.5.x hosts if any
EOF

# Validate configuration
named-checkconf
named-checkzone basile.uha.fr /etc/bind/zones/db.basile.uha.fr
named-checkzone 4.129.10.in-addr.arpa /etc/bind/zones/db.10.129.4
named-checkzone 5.129.10.in-addr.arpa /etc/bind/zones/db.10.129.5

# Restart and enable BIND9
systemctl restart named
systemctl enable named
echo "Primary DNS Server configured with domain basile.uha.fr"

# Use our own DNS server
echo "nameserver 127.0.0.1" > /etc/resolv.conf

echo "================================================================"
echo "Primary DNS server configured for basile.uha.fr domain"
echo "Secondary DNS server configured at ${DNS_SECONDARY_IP}"
echo "================================================================"
