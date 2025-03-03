# GitLab on Proxmox Terraform Project

This Terraform project deploys GitLab CE on a Debian 12 LXC container running on Proxmox.

## Prerequisites

- Proxmox server running at proxmox.basile.local
- The Debian 12 template (`debian-12-standard_12.7-1_amd64.tar.zst`) available on your Proxmox host
- Terraform installed on your local machine
- API token for Proxmox with appropriate permissions

## Setup

1. Clone this repository
2. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill in your specific values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

3. Edit `terraform.tfvars` to match your environment

## Deployment

1. Initialize Terraform:

```bash
terraform init -reconfigure
terraform validate
terraform plan -out=plan.out
```

2. Deploy the container and install GitLab:

```bash
terraform apply plan.out
```

The deployment process automatically:
- Provisions the LXC container
- Runs the setup script that installs the auto-update utility
- Installs and configures GitLab CE

## Post-Installation

1. Add the following entry to your local `/etc/hosts` file:

```
<container_ip> gitlab.basile.local
```

2. Access GitLab at https://gitlab.basile.local and set up the admin account

## Notes

- The container requires direct internet access to download packages
- The configuration follows the requirements in `docs/gitlab.md`
- SSL is configured with a self-signed certificate
- The auto-update utility is installed to keep the system updated automatically
- Docker and GitLab runner are not installed with this Terraform configuration

## Resource Specifications

- 6 CPU cores
- 8GB RAM 
- 32GB storage
- Network configured in bridge mode
