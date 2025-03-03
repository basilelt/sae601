#!/bin/bash

# Script to set up SSH on the container

CONTAINER_ID=$1
PROXMOX_HOST=$2

echo "Setting up SSH on container $CONTAINER_ID on host $PROXMOX_HOST"

# SSH into the Proxmox host and execute commands to configure SSH on the container
ssh root@$PROXMOX_HOST << EOF
# Enter the container and set up SSH
pct enter $CONTAINER_ID << 'INNEREOF'
apt update 
apt install -y openssh-server
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl restart ssh
exit
INNEREOF

echo "SSH has been configured on container $CONTAINER_ID"
EOF

# Give SSH service time to start fully
echo "Waiting 10 seconds for SSH to start completely..."
sleep 10

exit 0
