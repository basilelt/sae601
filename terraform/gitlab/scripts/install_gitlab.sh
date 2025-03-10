#!/bin/bash

# This script should be executed on the LXC container after provisioning
# Usage: Copy to the container and run with bash

set -e
echo "Starting GitLab installation script..."

# 1. Update system and install prerequisites
apt-get update && apt-get upgrade -y
apt-get install -y curl openssh-server ca-certificates apt-transport-https gnupg lsb-release

# 2. Create directories for certificates
echo "Setting up directories for certificates..."
mkdir -p /etc/gitlab/ssl

# 3. Generate self-signed certificate
echo "Generating self-signed certificate..."
cat > /tmp/gitlab.basile.local.cnf << EOF
[ req ]
default_bits       = 2048
distinguished_name = req_distinguished_name
req_extensions     = req_ext
prompt             = no
[ req_distinguished_name ]
countryName                = FR
stateOrProvinceName        = GRAND EST
localityName               = COLMAR
organizationName           = IUT
commonName                 = gitlab.basile.local
[ req_ext ]
subjectAltName = @alt_names
[alt_names]
DNS.1  = gitlab.basile.local
EOF

openssl genpkey -out /etc/gitlab/ssl/gitlab.basile.local.key -algorithm RSA -pkeyopt rsa_keygen_bits:2048
openssl req -new -key /etc/gitlab/ssl/gitlab.basile.local.key -out /tmp/gitlab.basile.local.csr -config /tmp/gitlab.basile.local.cnf
openssl x509 -signkey /etc/gitlab/ssl/gitlab.basile.local.key -in /tmp/gitlab.basile.local.csr -req -copy_extensions copyall -days 365 -out /etc/gitlab/ssl/gitlab.basile.local.crt

echo "Installing certificate on Debian/Ubuntu system..."
cp /etc/gitlab/ssl/gitlab.basile.local.crt /usr/local/share/ca-certificates/gitlab.basile.local.crt
update-ca-certificates

# 4. Install GitLab CE package
echo "Installing GitLab CE repository..."
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | bash

# Set external URL - replace with actual domain if available
GITLAB_DOMAIN="${GITLAB_DOMAIN:-localhost}"
GITLAB_EXTERNAL_URL="http://$GITLAB_DOMAIN"

echo "Installing GitLab CE package with HTTP configuration..."
EXTERNAL_URL="http://gitlab.basile.local" apt-get install -y gitlab-ce

# 5. Configure HTTPS
echo "Configuring HTTPS for GitLab..."
cat > /etc/gitlab/gitlab.rb << EOF
external_url 'https://gitlab.basile.local'
nginx['redirect_http_to_https'] = true
nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.basile.local.crt"
nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.basile.local.key"

# Registry settings
registry_external_url 'https://gitlab.basile.local:5050'
registry_nginx['ssl_certificate'] = "/etc/gitlab/ssl/gitlab.basile.local.crt"
registry_nginx['ssl_certificate_key'] = "/etc/gitlab/ssl/gitlab.basile.local.key"
EOF

# 6. Reconfigure GitLab
echo "Reconfiguring GitLab with new settings..."
gitlab-ctl reconfigure

# 7. Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 8. Install cert for registry
mkdir -p /etc/docker/certs.d/gitlab.basile.local:5050
cp /etc/gitlab/ssl/gitlab.basile.local.crt /etc/docker/certs.d/gitlab.basile.local:5050/ca.crt
systemctl restart docker

# 9. Install gitlab-runner
echo "Installing gitlab-runner..."
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
apt-get install gitlab-runner -y

# 10. Install and Configure BIND9 DNS Server
echo "Installing BIND9 DNS Server..."
apt-get install -y bind9 bind9utils bind9-doc
# Configure BIND9 options
cat > /etc/bind/named.conf.options << EOF
options {
    directory "/var/cache/bind";
    
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    allow-query {
        localhost;
        10.0.0.0/8;
    };

    recursion yes;
    dnssec-validation no;
    listen-on { 10.30.1.11; };
};
EOF

# Configure zones
cat > /etc/bind/named.conf.local << EOF
zone "basile.local" {
    type master;
    file "/etc/bind/zones/db.basile.local";
};

zone "30.10.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/db.10.30";
};
EOF
# Create zone directory
mkdir -p /etc/bind/zones
# Create forward zone file
cat > /etc/bind/zones/db.basile.local << EOF
\$TTL    604800
@       IN      SOA     ns1.basile.local. admin.basile.local. (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.basile.local.
ns1     IN      A       10.30.1.11

; Specific entry for cluster.basile.local
cluster IN      A       10.30.1.12
cluster IN      A       10.30.1.13
cluster IN      A       10.30.1.14

; Wildcard for cluster subdomain pointing to all masters
*.cluster IN      A       10.30.1.12
*.cluster IN      A       10.30.1.13
*.cluster IN      A       10.30.1.14

; Kubernetes masters
master1 IN      A       10.30.1.12
master2 IN      A       10.30.1.13
master3 IN      A       10.30.1.14

; GitLab server
gitlab  IN      A       10.30.1.11
EOF
# Create reverse zone file
cat > /etc/bind/zones/db.10.30 << EOF
\$TTL    604800
@       IN      SOA     ns1.basile.local. admin.basile.local. (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
;
@       IN      NS      ns1.basile.local.

; PTR Records
11      IN      PTR     gitlab.basile.local.
12      IN      PTR     master1.basile.local.
13      IN      PTR     master2.basile.local.
14      IN      PTR     master3.basile.local.
EOF
# Validate configuration
named-checkconf
named-checkzone basile.local /etc/bind/zones/db.basile.local
named-checkzone 30.10.in-addr.arpa /etc/bind/zones/db.10.30
# Restart and enable BIND9
systemctl restart named
systemctl enable named
echo "DNS Server configured with domain basile.local"

# 11. Configure the host to use itself as DNS server
echo "Configuring the host to use the local DNS server..."
# Get the main network interface
MAIN_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
echo "Main network interface is $MAIN_INTERFACE"
# Create or modify netplan configuration for Ubuntu 24.04
cat > /etc/netplan/99-custom-dns.yaml << EOF
network:
  version: 2
  ethernets:
    ${MAIN_INTERFACE}:
      nameservers:
        addresses: [127.0.0.1]
        search: [basile.local]
EOF
chmod 600 /etc/netplan/99-custom-dns.yaml
# Apply netplan configuration
netplan apply
# Verify DNS configuration
echo "Verifying DNS configuration..."
nslookup gitlab.basile.local
nslookup master1.basile.local

# 12. Copy admin password generated by gitlab to /home/ubuntu
echo "Copying admin password to /home/ubuntu..."
ADMIN_PASSWORD=$(grep 'Password:' /etc/gitlab/initial_root_password | awk '{print $NF}')
echo "Admin password: $ADMIN_PASSWORD"
echo "Admin password: $ADMIN_PASSWORD" > /home/ubuntu/gitlab_admin_password.txt
chown ubuntu:ubuntu /home/ubuntu/gitlab_admin_password.txt

echo "================================================================"
echo "GitLab installation complete!"
echo "Access GitLab at https://gitlab.basile.local"
echo "DNS server configured for basile.local domain"
echo "Host configured to use local DNS server"
echo "================================================================"
