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
  vm_id        = var.gitlab_vm_id
  
  # Clone from template with storage target specified
  clone {
    vm_id = var.template_vm_id
    full  = true
    datastore_id = var.storage_pool
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
  
  # Disk configuration
  disk {
    datastore_id = var.storage_pool
    size         = 32
    interface    = "scsi0"
    discard      = "on"
    file_format  = "raw"
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
      username = "root"
      password = "root"
      keys     = [var.ssh_public_keys]
    }
    
    # Cloud-init settings as part of the standard configuration
    # Remove the user_data attribute and instead use these settings:
    datastore_id = var.storage_pool
    interface    = "ide2"
  }

  operating_system {
    type = "l26"
  }

  # Add cloud-init custom settings outside initialization block
  lifecycle {
    ignore_changes = [
      initialization[0].datastore_id,
    ]
  }
}

# Use local-exec instead of remote-exec initially to wait for VM to be accessible
resource "null_resource" "wait_for_vm" {
  depends_on = [proxmox_virtual_environment_vm.gitlab]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for VM to become accessible..."
      count=0
      max_attempts=30
      until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_private_key_path} root@${var.ip_address} echo "VM is accessible" || [ $count -eq $max_attempts ]
      do
        sleep 10
        count=$((count+1))
        echo "Attempt $count/$max_attempts: Waiting for VM to be accessible..."
      done
    EOT
  }
}

# Use a separate null_resource for provisioners after we know the VM is accessible
resource "null_resource" "gitlab_provisioner" {
  depends_on = [null_resource.wait_for_vm]

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
