#!/bin/bash

echo "Resetting Terraform state for GitLab deployment..."

# Remove the Terraform state files
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
rm -rf .terraform/

# Reinitialize Terraform
terraform init

echo "Terraform state has been reset. You can now run:"
echo "terraform plan -out=gitlab.tfplan"
echo "terraform apply gitlab.tfplan"
