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

# 8. Copy admin password generated by gitlab to /home/ubuntu
echo "Copying admin password to /home/ubuntu..."
ADMIN_PASSWORD=$(grep 'Password:' /etc/gitlab/initial_root_password | awk '{print $NF}')
echo "Admin password: $ADMIN_PASSWORD"
echo "Admin password: $ADMIN_PASSWORD" > /home/ubuntu/gitlab_admin_password.txt
chown ubuntu:ubuntu /home/ubuntu/gitlab_admin_password.txt

echo "================================================================"
echo "GitLab installation complete!"
echo "Access GitLab at https://gitlab.basile.local"
echo "================================================================"
