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

# Primary DNS server container
resource "proxmox_virtual_environment_container" "dns_primary" {
  node_name    = var.proxmox_node
  vm_id        = var.dns_primary_container_id
  started      = true
  
  # Template source
  template_file_id = var.container_template_file_id
  
  # Features
  features {
    nesting = true
    fuse    = true
  }
  
  # Operating system settings
  operating_system {
    type = "debian"
  }
  
  # Container settings
  cpu {
    cores = 1
  }
  memory {
    dedicated = 512
  }
  
  # Root filesystem
  rootfs {
    datastore_id = var.storage_pool
    size         = 8
  }
  
  # Network configuration
  network_interface {
    name     = "eth0"
    bridge   = var.network_bridge
    ip_addresses = ["${var.dns_primary_ip}/24"]
    gateway     = var.gateway_ip
  }
  
  initialization {
    hostname = "dns-primary"
    dns {
      domain  = var.domain
      servers = var.nameserver
    }
    user_account {
      username = "root"
      password = var.root_password
      keys     = [var.ssh_public_keys]
    }
  }
  
  # Provide some identifying information
  tags = ["dns", "primary"]
}

# Secondary DNS server container
resource "proxmox_virtual_environment_container" "dns_secondary" {
  node_name    = var.proxmox_node
  vm_id        = var.dns_secondary_container_id
  started      = true
  
  # Template source
  template_file_id = var.container_template_file_id
  
  # Features
  features {
    nesting = true
    fuse    = true
  }
  
  # Operating system settings
  operating_system {
    type = "debian"
  }
  
  # Container settings
  cpu {
    cores = 1
  }
  memory {
    dedicated = 512
  }
  
  # Root filesystem
  rootfs {
    datastore_id = var.storage_pool
    size         = 8
  }
  
  # Network configuration
  network_interface {
    name     = "eth0"
    bridge   = var.network_bridge
    ip_addresses = ["${var.dns_secondary_ip}/24"]
    gateway     = var.gateway_ip
  }
  
  initialization {
    hostname = "dns-secondary"
    dns {
      domain  = var.domain
      servers = var.nameserver
    }
    user_account {
      username = "root"
      password = var.root_password
      keys     = [var.ssh_public_keys]
    }
  }
  
  # Provide some identifying information
  tags = ["dns", "secondary"]
}

# Use local-exec to wait for primary DNS container to be accessible
resource "null_resource" "wait_for_primary_dns" {
  depends_on = [proxmox_virtual_environment_container.dns_primary]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for primary DNS container to become accessible..."
      count=0
      max_attempts=30
      until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_private_key_path} root@${var.dns_primary_ip} echo "DNS primary is accessible" || [ $count -eq $max_attempts ]
      do
        sleep 10
        count=$((count+1))
        echo "Attempt $count/$max_attempts: Waiting for primary DNS to be accessible..."
      done
    EOT
  }
}

# Use local-exec to wait for secondary DNS container to be accessible
resource "null_resource" "wait_for_secondary_dns" {
  depends_on = [proxmox_virtual_environment_container.dns_secondary]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for secondary DNS container to become accessible..."
      count=0
      max_attempts=30
      until ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_private_key_path} root@${var.dns_secondary_ip} echo "DNS secondary is accessible" || [ $count -eq $max_attempts ]
      do
        sleep 10
        count=$((count+1))
        echo "Attempt $count/$max_attempts: Waiting for secondary DNS to be accessible..."
      done
    EOT
  }
}

# Provision primary DNS server
resource "null_resource" "primary_dns_provisioner" {
  depends_on = [null_resource.wait_for_primary_dns]

  # Copy setup scripts
  provisioner "file" {
    source      = "${path.module}/scripts/install_dns_primary.sh"
    destination = "/tmp/install_dns.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.dns_primary_ip
      private_key = file(var.ssh_private_key_path)
    }
  }
  
  # Execute setup scripts
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_dns.sh",
      "echo 'Installing primary DNS server...'",
      "DNS_SECONDARY_IP=${var.dns_secondary_ip} bash /tmp/install_dns.sh"
    ]
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.dns_primary_ip
      private_key = file(var.ssh_private_key_path)
    }
  }
}

# Provision secondary DNS server (Only after primary is configured)
resource "null_resource" "secondary_dns_provisioner" {
  depends_on = [null_resource.wait_for_secondary_dns, null_resource.primary_dns_provisioner]

  # Copy setup scripts
  provisioner "file" {
    source      = "${path.module}/scripts/install_dns_secondary.sh"
    destination = "/tmp/install_dns.sh"
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.dns_secondary_ip
      private_key = file(var.ssh_private_key_path)
    }
  }
  
  # Execute setup scripts
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_dns.sh",
      "echo 'Installing secondary DNS server...'",
      "DNS_PRIMARY_IP=${var.dns_primary_ip} bash /tmp/install_dns.sh"
    ]
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.dns_secondary_ip
      private_key = file(var.ssh_private_key_path)
    }
  }
}
