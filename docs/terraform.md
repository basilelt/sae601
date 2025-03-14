# Terraform Deployment Projects for Proxmox

This Terraform project deploys both GitLab CE on a Ubuntu 24.04 VM and a Kubernetes cluster using VMs on Proxmox.

## Prerequisites

- Proxmox server running at proxmox.basile.local
- Ubuntu 24.04 cloud image template for all VMs (with qemu-guest-agent installed)
- Template Debian 12
- Terraform installed on your local machine
- API token for Proxmox with appropriate permissions

## Setup

1. Clone this repository
2. Edit `terraform.tfvars.example` with your specific values:

### DNS Server Deployment

1. Initialize Terraform:

```bash
tofu init (-reconfigure)
tofu validate
tofu plan -out=plan.out
```

2. Deploy the container and install Bind9:

```bash
tofu apply plan.out
```

The deployment process automatically:
- Provisions the DNS VM
- Runs the setup script that installs the auto-update utility
- Installs and configures DNS bind9

### GitLab Deployment

1. Initialize Terraform:

```bash
tofu init (-reconfigure)
tofu validate
tofu plan -out=plan.out
```

2. Deploy the container and install GitLab:

```bash
tofu apply plan.out
```

The deployment process automatically:
- Provisions the GitLab VM
- Runs the setup script that installs the auto-update utility
- Installs and configures GitLab CE

### Kubernetes Deployment

1. Initialize and deploy the Kubernetes VMs:

```bash
tofu init -reconfigure
tofu validate
tofu plan -out=plan.out
```

2. Deploy the container and install GitLab:

```bash
tofu apply plan.out
```

The deployment process automatically:
- Provisions the required VMs (3 control planes)

## Post-Installation

### GitLab

1. Add the following entry to your local `/etc/hosts` file:

```
<vm_ip> gitlab.basile.local
```
A DNS server is also present on the gitlab VM, you could use it instead.

2. Access GitLab at https://gitlab.basile.local and set up the admin account

### Kubernetes

1. The Kubernetes kubeconfig will be saved to your local machine at `~/.kube/config` or as specified in your variables

2. Verify the cluster is working:

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## Resource Specifications

### GitLab VM
- 6 CPU cores
- 8GB RAM 
- 32GB storage
- Network configured in bridge mode

### Kubernetes VMs
- Control Plane: 6 CPU cores, 2048MB RAM, 32GB storage
- Worker Nodes: 6 CPU cores, 2048MB RAM, 32GB storage each
- All VMs configured with bridge networking

## Notes

- All deployments require direct internet access to download packages
- The auto-update utility is installed on all machines to keep systems updated automatically
