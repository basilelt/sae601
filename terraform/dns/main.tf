terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.73.1"
    }
  }
}

provider "proxmox" {
  endpoint      = var.proxmox_api_url
  api_token     = var.proxmox_api_token
  insecure      = var.proxmox_tls_insecure
  tmp_dir       = "/tmp"
}

# Primary DNS server container
resource "proxmox_virtual_environment_container" "dns_primary" {
  node_name = var.proxmox_node
  vm_id     = var.dns_primary_container_id
  started   = true
  tags      = ["dns", "primary"]
  
  initialization {
    hostname = "ns1"
    
    ip_config {
      ipv4 {
        address = "${var.dns_primary_ip}/24"
        gateway = var.gateway_ip
      }
    }
    
    dns {
      domain  = var.domain
      servers = var.nameserver
    }
    
    user_account {
      keys     = [var.ssh_public_keys]
      password = var.root_password
    }
  }
  
  cpu {
    cores = 1
  }
  
  memory {
    dedicated = 512
    swap      = 0
  }
  
  operating_system {
    template_file_id = var.container_template_file_id
    type             = "debian"
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }
  
  disk {
    datastore_id = var.storage_pool
    size         = 8
  }
  
  unprivileged = true
  start_on_boot = true
  
  # Connection for provisioning
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = var.dns_primary_ip
  }
  
  # Wait for system to be available
  provisioner "remote-exec" {
    inline = ["echo 'System is up'"]
  }
  
  # Provisioning - Basic setup
  provisioner "file" {
    source      = "${path.module}/scripts/setup.sh"
    destination = "/tmp/setup.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "/tmp/setup.sh",
      "sleep 5"
    ]
  }
  
  # Provisioning - DNS primary setup
  provisioner "file" {
    source      = "${path.module}/scripts/install_dns_primary.sh"
    destination = "/tmp/install_dns_primary.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_dns_primary.sh",
      "DNS_SECONDARY_IP=${var.dns_secondary_ip} /tmp/install_dns_primary.sh"
    ]
  }
}

# Secondary DNS server container
resource "proxmox_virtual_environment_container" "dns_secondary" {
  node_name = var.proxmox_node
  vm_id     = var.dns_secondary_container_id
  started   = true
  tags      = ["dns", "secondary"]
  
  initialization {
    hostname = "ns2"
    
    ip_config {
      ipv4 {
        address = "${var.dns_secondary_ip}/24"
        gateway = var.gateway_ip
      }
    }
    
    dns {
      domain  = var.domain
      servers = var.nameserver
    }
    
    user_account {
      keys     = [var.ssh_public_keys]
      password = var.root_password
    }
  }
  
  cpu {
    cores = 1
  }
  
  memory {
    dedicated = 512
    swap      = 0
  }
  
  operating_system {
    template_file_id = var.container_template_file_id
    type             = "debian"
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }
  
  disk {
    datastore_id = var.storage_pool
    size         = 8
  }
  
  unprivileged = true
  start_on_boot = true
  
  # Connection for provisioning
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
    host        = var.dns_secondary_ip
  }
  
  # Wait for system to be available
  provisioner "remote-exec" {
    inline = ["echo 'System is up'"]
  }
  
  # Provisioning - Basic setup
  provisioner "file" {
    source      = "${path.module}/scripts/setup.sh"
    destination = "/tmp/setup.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh",
      "/tmp/setup.sh",
      "sleep 5"
    ]
  }
  
  # Provisioning - DNS secondary setup
  provisioner "file" {
    source      = "${path.module}/scripts/install_dns_secondary.sh"
    destination = "/tmp/install_dns_secondary.sh"
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_dns_secondary.sh",
      "DNS_PRIMARY_IP=${var.dns_primary_ip} /tmp/install_dns_secondary.sh"
    ]
  }
  
  # Make sure primary is created first
  depends_on = [proxmox_virtual_environment_container.dns_primary]
}

# Output the DNS server IPs
output "dns_primary_ip" {
  value = var.dns_primary_ip
}

output "dns_secondary_ip" {
  value = var.dns_secondary_ip
}
