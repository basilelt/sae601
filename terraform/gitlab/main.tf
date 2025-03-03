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

resource "proxmox_lxc" "gitlab" {
  target_node     = var.proxmox_node
  hostname        = "gitlab.basile.local"
  ostemplate      = "local:vztmpl/${var.debian_template}"
  password        = var.root_password
  unprivileged    = true
  start           = true
  onboot          = true
  
  // Resource allocation as per prerequisites in terraform_gitlab.md
  cores  = 6
  memory = 8192
  swap   = 0
  
  // Storage allocation - 32G as specified in docs
  rootfs {
    storage = var.storage_pool
    size    = "32G"
  }
  
  // Network in bridge mode
  network {
    name   = "eth0"
    bridge = var.network_bridge
    ip     = "${var.ip_address}/24"
    gw     = var.gateway_ip
  }

  // DNS configuration
  nameserver = var.nameserver
  searchdomain = "basile.local"
  
  // Enable FUSE for container
  features {
    fuse = true
  }

  // Install and configure SSH on startup
  startup = "apt-get update && apt-get install -y openssh-server && echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && systemctl restart ssh"

  // Wait for SSH to become available
  provisioner "remote-exec" {
    inline = ["echo 'SSH is up and running!'"]
    
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = var.ip_address
      // Add a timeout to give the container time to setup SSH
      timeout  = "2m"
    }
  }
  
  // Provisioning: Copy and execute scripts in order
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
