terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
  
  # LOGS
  pm_log_enable = true
  pm_log_file = "terraform-plugin-proxmox.log"
  pm_debug = true
  pm_log_levels = {
    _default = "debug"
    _capturelog = ""
  }
}

resource "proxmox_vm_qemu" "gitlab" {
  target_node     = var.proxmox_node
  name            = "gitlab"
  desc            = "GitLab server VM"
  
  # Clone from template (replace TEMPLATE_ID with your template ID or name)
  clone           = var.template_name
  full_clone      = true
  
  # VM specific settings
  qemu_os         = "l26" # Linux 2.6+ kernel
  scsihw          = "virtio-scsi-pci"
  boot            = "cdn"  # First CD-ROM, then disk, then network
  bootdisk        = "scsi0"
  
  # Resource allocation as per GitLab requirements
  cores           = 6
  sockets         = 1
  cpu             = "host"
  memory          = 8192
  
  # Disk configuration
  # When using a template, the disk is already created
  # You can resize it if needed:
  disk {
    type          = "scsi"
    storage       = var.storage_pool
    size          = "32G"
    discard       = "on"
  }
  
  # Network configuration
  network {
    model         = "virtio"
    bridge        = var.network_bridge
  }
  
  # Cloud-init configuration
  ipconfig0       = "ip=${var.ip_address}/24,gw=${var.gateway_ip}"
  nameserver      = var.nameserver
  searchdomain    = "basile.local"
  
  # SSH keys for cloud-init
  sshkeys = var.ssh_public_keys

  # Wait for the VM to get an IP address before proceeding
  provisioner "remote-exec" {
    inline = ["echo 'VM is up and running!'"]
    
    connection {
      type        = "ssh"
      user        = "root"  # or appropriate user from cloud-init
      host        = var.ip_address
      private_key = file(var.ssh_private_key_path)
      timeout     = "5m"
    }
  }
  
  # Copy setup scripts
  provisioner "file" {
    source      = "${path.module}/scripts/setup.sh"
    destination = "/tmp/setup.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.ip_address
      private_key = file(var.ssh_private_key_path)
    }
  }
  
  provisioner "file" {
    source      = "${path.module}/scripts/install_gitlab.sh"
    destination = "/tmp/install_gitlab.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.ip_address
      private_key = file(var.ssh_private_key_path)
    }
  }
  
  # Execute setup scripts
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "chmod +x /tmp/install_gitlab.sh",
      "echo 'Running setup script first...'",
      "bash /tmp/setup.sh",
      "echo 'Now installing GitLab...'",
      "bash /tmp/install_gitlab.sh"
    ]
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.ip_address
      private_key = file(var.ssh_private_key_path)
    }
  }
}
