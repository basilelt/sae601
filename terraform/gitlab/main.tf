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

# Create a VM for GitLab
resource "proxmox_vm_qemu" "gitlab" {
  target_node     = var.proxmox_node
  name            = "gitlab"
  desc            = "GitLab Server"
  vmid            = var.vm_id
  
  # Use Debian ISO for installation
  iso             = "local:iso/${var.debian_iso}"
  
  # VM hardware configuration
  cores           = 6
  sockets         = 1
  cpu             = "host"
  memory          = 8192
  
  # VM disk
  disk {
    size          = "32G"
    type          = "scsi"
    storage       = var.storage_pool
    iothread      = 1
  }
  
  # VM network
  network {
    model         = "virtio"
    bridge        = var.network_bridge
    tag           = -1
  }
  
  # Enable QEMU guest agent
  agent           = 1
  
  # Start on boot
  onboot          = true
  
  lifecycle {
    create_before_destroy = true
  }
}
