#!/bin/bash

set -e

echo "Starting VM setup..."

# Update system packages
apt-get update
apt-get upgrade -y

# Install required dependencies
apt-get install -y curl ca-certificates tzdata perl

# Set up basic system configuration
timedatectl set-timezone Europe/Paris

# Set keyboard layout to Swiss French
echo "Setting keyboard layout to Swiss French..."
apt-get install -y console-setup
cat > /etc/default/keyboard << EOF
XKBMODEL="pc105"
XKBLAYOUT="ch"
XKBVARIANT="fr"
XKBOPTIONS=""
BACKSPACE="guess"
EOF
dpkg-reconfigure -f noninteractive keyboard-configuration
setupcon

# Configure firewall (if needed)
apt-get install -y ufw
ufw allow ssh
ufw allow http
ufw allow https
# Will be enabled later if needed

echo "Basic VM setup complete!"

# Script to clone and install auto-update
# Create a temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
# Clone the repository
echo "Cloning auto-update repository..."
git clone https://github.com/noloader/auto-update.git
cd auto-update
# Install the script as root
./install.sh
# Clean up
cd / && rm -rf "$TEMP_DIR"

# Disable swap
echo "Disabling swap..."
swapoff -a
# Remove swap entries from fstab to prevent re-enabling at boot
sed -i '/\bswap\b/d' /etc/fstab

# Add entries to /etc/hosts
echo "Adding host entries to /etc/hosts..."
cat << EOF >> /etc/hosts
10.30.1.10 proxmox.basile.local
10.30.1.12 master1.basile.local
10.30.1.13 master2.basile.local
10.30.1.14 master3.basile.local
EOF

echo "Configuring cloud-init to preserve /etc/hosts entries..."
# Disable manage_etc_hosts in cloud.cfg
if grep -q "manage_etc_hosts" /etc/cloud/cloud.cfg; then
    sed -i 's/manage_etc_hosts: true/manage_etc_hosts: false/' /etc/cloud/cloud.cfg
else
    echo "manage_etc_hosts: false" >> /etc/cloud/cloud.cfg
fi

# Install git if not already installed
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    apt-get update
    apt-get install -y git
fi

echo "auto-update has been installed successfully!"
echo "It will run daily via systemd to keep the system updated."
echo "Swap has been disabled permanently."
echo "Host entries have been added to /etc/hosts."
