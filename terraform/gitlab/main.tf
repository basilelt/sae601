terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.73.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_api_url
  api_token = var.proxmox_api_token
  insecure  = true
}

resource "proxmox_virtual_environment_vm" "gitlab" {
  node_name    = var.proxmox_node
  name         = "gitlab"
  description  = "GitLab server VM"
  vm_id        = var.gitlab_vm_id  # Use the specified VM ID if provided
  
  # Clone from template with storage target specified
  clone {
    vm_id = var.template_vm_id
    full  = true
    datastore_id = var.storage_pool  # Specify target storage for clone
  }
  
  # VM specific settings
  agent {
    enabled = true
  }
  
  # Resource allocation
  cpu {
    cores   = 6
    sockets = 1
    type    = "host"
  }
  memory {
    dedicated = 8192
  }
  
  # Disk configuration - specify raw format for LVM thin
  disk {
    datastore_id = var.storage_pool
    size         = 32
    interface    = "scsi0"
    discard      = "on"
    file_format  = "raw"  # Explicitly set format compatible with LVM thin
  }
  
  # Network configuration
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }
  
  # Cloud-init configuration
  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address}/24"
        gateway = var.gateway_ip
      }
    }
    
    dns {
      domain = "basile.local"
      servers = var.nameserver
    }
    
    user_account {
      username  = "root"
      keys      = [var.ssh_public_keys]
    }
  }

  # Wait for the VM to get an IP address before proceeding
  depends_on = [
    # Only proceed after the VM is fully initialized
  ]
}

# Use a null_resource for provisioners
resource "null_resource" "gitlab_provisioner" {
  # Only run this after the VM is ready
  depends_on = [proxmox_virtual_environment_vm.gitlab]

  # Trigger re-provisioning when VM changes
  triggers = {
    vm_id = proxmox_virtual_environment_vm.gitlab.id
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
