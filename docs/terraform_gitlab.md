# GitLab on Proxmox Terraform Project

This Terraform project deploys GitLab CE on a Debian 12 virtual machine running on Proxmox.

## Prerequisites

- Proxmox server running at proxmox.basile.local
- The Debian 12 cloud-init ISO (`debian-12-cloud.iso`) available on your Proxmox host
- Terraform installed on your local machine
- API token for Proxmox with appropriate permissions
- Host name resolution configured (see [hosts configuration](hosts_configuration.md))

## Setup

1. Clone this repository
2. Edit `terraform.tfvars` to match your environment
3. Make sure your `/etc/hosts` file is configured with the correct entries (see [hosts configuration](hosts_configuration.md))

## Deployment

1. Run the deployment:

```bash
terraform init --upgrade
terraform plan -out=gitlab.tfplan
terraform apply gitlab.tfplan
```

The deployment process automatically:
- Provisions the virtual machine
- Runs the setup script that installs the auto-update utility
- Installs Docker for container support
- Installs and configures GitLab CE

## Post-Installation

1. Verify that your hosts file contains the correct entry for GitLab:
```
192.168.2.11 gitlab.basile.local
```

2. Access GitLab at https://gitlab.basile.local and set up the admin account

## Notes

- The virtual machine requires direct internet access to download packages
- The configuration follows the requirements in `docs/gitlab.md`
- SSL is configured with a self-signed certificate
- The auto-update utility is installed to keep the system updated automatically
- Docker is installed for container support
- GitLab runner is not installed with this Terraform configuration

## Resource Specifications

- 6 CPU cores
- 8GB RAM 
- 32GB storage
- Network configured in bridge mode
