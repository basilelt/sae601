#!/bin/bash

# Script to clone and install auto-update
# https://github.com/noloader/auto-update

set -e  # Exit on error
echo "Setting up auto-update script..."

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
