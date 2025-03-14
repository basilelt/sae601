# Proxmox API Token Setup for Terraform

This guide explains how to create a Proxmox user with appropriate permissions and generate an API token for use with Terraform.

## Create User Account

Create a dedicated user account for Terraform:

```bash
pveum user add terraform@pve
```

## Create and Assign Role

Create a custom role with the necessary privileges for Terraform operations:

```bash
pveum role add Terraform -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Pool.Allocate Sys.Audit Sys.Console Sys.Modify SDN.Use VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.Cloudinit VM.Config.CPU VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Migrate VM.Monitor VM.PowerMgmt User.Modify"
```

Assign this role to the Terraform user at the root level:

```bash
pveum aclmod / -user terraform@pve -role Terraform
```

## Generate API Token

Create an API token for the Terraform user:

```bash
pveum user token add terraform@pve provider --privsep=0
```

Save the token ID and secret value that is displayed after running this command. They will be needed for your Terraform configuration.

## Next Steps

After completing these steps, configure your Terraform provider with the token ID and secret value. Refer to the proxmox.md file for more details on token configuration in the Proxmox web interface.
