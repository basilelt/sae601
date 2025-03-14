# Ubuntu Cloud-Init Template for Proxmox

This guide walks through creating an Ubuntu 24.04 cloud-init template VM in Proxmox. This template can be used as a base image for quickly creating new VMs with cloud-init support.

## Prerequisites

- Proxmox VE installed and configured
- Internet access to download the Ubuntu cloud image
- Storage space available in the local-lvm storage

## Download Cloud Image

Download the Ubuntu 24.04 cloud image to the Proxmox template storage:

```bash
wget -P /var/lib/vz/template/iso/ https://cloud-images.ubuntu.com/daily/server/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img
```

## Create VM Template

### 1. Create the base VM

```bash
qm create 9000 --name "ubuntu-cloud-init-template" --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
```

### 2. Import the cloud image disk

```bash
qm importdisk 9000 /var/lib/vz/template/iso/ubuntu-24.04-server-cloudimg-amd64.img local-lvm
```

### 3. Configure storage and boot options

```bash
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
```

### 4. Add cloud-init drive

```bash
qm set 9000 --ide2 local-lvm:cloudinit
```

### 5. Configure networking and default credentials

```bash
qm set 9000 --ipconfig0 ip=dhcp
qm set 9000 --ciuser ubuntu --cipassword 'ubuntu'
```

## Enable QEMU Guest Agent

Enable the QEMU Guest Agent with this command:

```bash
qm set 9000 --agent enabled=1
```

Note: The QEMU Guest Agent will be automatically installed in Ubuntu cloud images, but it needs to be enabled in the VM configuration.

## Convert VM to Template

Once the VM is properly configured, convert it to a template:

```bash
qm template 9000
```

## Usage

You can now create new VMs based on this template using the Proxmox web interface or by using the `qm clone` command.
