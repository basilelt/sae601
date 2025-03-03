#!/bin/bash

# Script to clone and install auto-update
# https://github.com/noloader/auto-update

set -e  # Exit on error
echo "Setting up auto-update script..."

# Disable swap
echo "Disabling swap..."
swapoff -a
# Remove swap entries from fstab to prevent re-enabling at boot
sed -i '/\bswap\b/d' /etc/fstab

# Add entries to /etc/hosts
echo "Adding host entries to /etc/hosts..."
cat << EOF >> /etc/hosts
192.168.2.10       proxmox.basile.local
192.168.2.11       gitlab.basile.local
192.168.2.12       master1.basile.local
192.168.2.13       master2.basile.local
192.168.2.14       master3.basile.local
EOF

# Install git if not already installed
if ! command -v git &> /dev/null; then
    echo "Installing git..."
    apt-get update
    apt-get install -y git
fi

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
cd /
rm -rf "$TEMP_DIR"

echo "auto-update has been installed successfully!"
echo "It will run daily via systemd to keep the system updated."
echo "Swap has been disabled permanently."
echo "Host entries have been added to /etc/hosts."
