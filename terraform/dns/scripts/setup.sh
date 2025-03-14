#!/bin/bash

set -e

echo "Starting VM setup..."

# Update system packages
apt-get update && apt-get upgrade -y

# Configure firewall (if needed)
apt-get install -y ufw
ufw allow ssh
ufw allow domain
ufw allow 53/udp
ufw allow 53/tcp
# Will be enabled later if needed

echo "Basic VM setup complete!"

# Script to clone and install auto-update
# Create a temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR" || exit
# Clone the repository
echo "Cloning auto-update repository..."
git clone https://github.com/noloader/auto-update.git
cd auto-update || exit
# Install the script as root
./install.sh
# Clean up
cd / && rm -rf "$TEMP_DIR"

echo "auto-update has been installed successfully!"
echo "It will run daily via systemd to keep the system updated."
