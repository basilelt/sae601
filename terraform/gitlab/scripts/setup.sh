#!/bin/bash

# Basic system setup script

set -e  # Exit on error

echo "Setting up basic system configuration..."

# Update system packages
apt-get update
apt-get upgrade -y

# Install common tools
apt-get install -y \
    sudo \
    vim \
    curl \
    wget \
    unzip \
    htop \
    net-tools \
    apt-transport-https \
    ca-certificates

# Setup automatic updates for security patches
apt-get install -y unattended-upgrades apt-listchanges
cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

# Configure timezone
timedatectl set-timezone Europe/Paris

echo "Basic system setup complete!"
