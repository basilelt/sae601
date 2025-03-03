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
  
  # This would only work with cloud-init enabled images
  ipconfig0       = "ip=${var.ip_address}/24,gw=${var.gateway_ip}"
  nameserver      = var.nameserver
  
  # Enable QEMU guest agent
  agent           = 1
  
  # Start on boot
  onboot          = true
}

# Example of user_data for cloud-init (if needed)
resource "local_file" "cloud_init_user_data" {
  content  = templatefile("${path.module}/templates/user_data.yml.tpl", {
    hostname      = "gitlab.basile.local"
    ssh_public_key = var.ssh_public_key
    root_password = var.root_password
  })
  filename = "${path.module}/files/user_data.yml"
}

# Wait for VM to be ready for SSH connection
resource "null_resource" "wait_for_vm" {
  depends_on = [proxmox_vm_qemu.gitlab]
  
  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for VM to become available..."
  provisioner "file" {
    source      = "${path.module}/scripts/setup.sh"
    destination = "/tmp/setup.sh"
    
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.ip_address
    }
  }
  
  provisioner "file" {
    source      = "${path.module}/scripts/install_gitlab.sh"
    destination = "/tmp/install_gitlab.sh"
    
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.ip_address
    }
  }
  
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
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.ip_address
    }
  }
}
