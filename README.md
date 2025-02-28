# SAE601 Infrastructure Project

This repository contains Terraform configurations for deploying various infrastructure components.

## Projects

- [GitLab](./terraform/gitlab/): Deploy GitLab on Proxmox using Terraform

## Usage

Navigate to the project directory before running Terraform commands:

```bash
# Change to the GitLab project directory
cd terraform/gitlab

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan

# Apply the configuration
terraform apply
```

## Documentation

See the [docs](./docs/) directory for more information about each component.
