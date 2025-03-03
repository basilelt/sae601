#!/bin/bash

echo "Removing old resources from Terraform state..."
terraform state rm proxmox_lxc.gitlab || echo "Resource doesn't exist in state, continuing..."
terraform state rm null_resource.gitlab_provisioning || echo "Resource doesn't exist in state, continuing..."

echo "Terraform state has been reset. You can now run terraform plan and apply."
