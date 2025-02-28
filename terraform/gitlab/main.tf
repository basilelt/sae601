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
}
