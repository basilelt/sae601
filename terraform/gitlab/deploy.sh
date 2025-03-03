#!/bin/bash

set -e

echo "Initializing Terraform..."
terraform init

echo "Cleaning up any old state issues..."
./reset_state.sh

echo "Creating VM (Phase 1)..."
terraform apply -target=proxmox_vm_qemu.gitlab -auto-approve

echo "Waiting for VM to boot (30 seconds)..."
sleep 30

echo "Provisioning GitLab (Phase 2)..."
terraform apply -auto-approve

echo "Deployment complete!"
echo "You can now access GitLab at https://gitlab.basile.local once provisioning completes."
