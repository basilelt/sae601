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

resource "proxmox_virtual_environment_vm" "kubernetes_nodes" {
  count        = length(var.ip_address_range)
  node_name    = var.proxmox_node
  name         = "kube-master${count.index + 1}"
  description  = "Kubernetes master ${count.index + 1}"
  vm_id        = var.gitlab_vm_id_range[count.index]
  
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
    dedicated = 2048
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
        address = "${var.ip_address_range[count.index]}/24"
        gateway = var.gateway_ip
      }
    }
    
    dns {
      domain = var.domain
      servers = var.nameserver
    }
    
    user_account {
      username = "root"
      password = var.root_password
      keys     = [var.ssh_public_keys]
    }
    
    datastore_id = var.storage_pool
    interface    = "ide2"
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [
      initialization[0].datastore_id,
    ]
  }
}

# Wait for each VM to be accessible
resource "null_resource" "wait_for_vm" {
  count = length(var.ip_address_range)
  depends_on = [proxmox_virtual_environment_vm.kubernetes_nodes]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for VM ${count.index + 1} to become accessible..."
      count=0
      max_attempts=30
      until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_private_key_path} root@${var.ip_address_range[count.index]} echo "VM is accessible" || [ $count -eq $max_attempts ]
      do
        sleep 10
        count=$((count+1))
        echo "Attempt $count/$max_attempts: Waiting for VM to be accessible..."
      done
    EOT
  }
}

# Provision each VM with setup scripts
resource "null_resource" "node_provisioner" {
  count = length(var.ip_address_range)
  depends_on = [null_resource.wait_for_vm]

  # Copy setup scripts
  provisioner "file" {
    source      = "${path.module}/scripts/setup.sh"
    destination = "/tmp/setup.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.ip_address_range[count.index]
      private_key = file(var.ssh_private_key_path)
    }
  }
  
  # Execute setup scripts
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "echo 'Running setup script for node ${count.index + 1}...'",
      "bash /tmp/setup.sh"
    ]
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.ip_address_range[count.index]
      private_key = file(var.ssh_private_key_path)
    }
  }
}
