variable "proxmox_api_url" {
  description = "The URL of the Proxmox API"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "API token ID for Proxmox authentication"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "API token secret for Proxmox authentication"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Whether to skip TLS verification for the Proxmox API"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "The name of the Proxmox node"
  type        = string
}

variable "proxmox_host" {
  description = "The hostname or IP address of the Proxmox host"
  type        = string
}

variable "debian_template" {
  description = "The Debian template to use"
  type        = string
  default     = "debian-12-standard_12.7-1_amd64.tar.zst"
}

variable "debian_iso" {
  description = "The Debian ISO to use for VM installation"
  type        = string
  default     = "debian-netinst-12.iso"
}

variable "root_password" {
  description = "Root password for the container"
  type        = string
  sensitive   = true
}

variable "storage_pool" {
  description = "Storage pool for container disk"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge for container"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "IP address for the GitLab container"
  type        = string
}

variable "gateway_ip" {
  description = "Gateway IP address"
  type        = string
}

variable "nameserver" {
  description = "DNS nameserver"
  type        = string
  default     = "1.1.1.1"
}

variable "vm_id" {
  description = "VM ID for the GitLab VM"
  type        = number
  default     = 100
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCeVpD3xpzoScNn05MfDcnlfx8BeOsbPk5xVARcxlCDKqM33Dti3gRJFgaRObgWl+SJSnAZq8QsRBkBe9Cj4Ah6VPM9Y0mGWVC00uSK2+opQHr1CDWOG/jaEevMTbxLxGNp/A1JyKgssRRvMIf3QI5qazJlwfWJzKC1zLlhDAyhmqfviri7+I9o+6wi/i0cEfAUOCXtOWxuyt18GsGm/ajRkwaxs+dzWWr/fkB9rLNYOtXtXa1z1Tn1veeTePUu1higquhL2FF3VRQ6wN7E/pGhoxz31n+2hKDSH8IMYuIV0Eu8u4WCVS8nFX6YG3ldJdDKw679b5fOMNM04cYk2OAPmLrleePNYGVqDopMWLaN4Nlu3Np0EjNlQNWvxOcwvgPnpcPJuVytmyDOEJfP3kqwJLW9V5A84O2K37i1CekIfIf0Gf7goVtqOTsU9cIPRmf6LN0cUDhbCKqDWaKdpAqUzSMERdE/muwnxHMR5FwIeH/ZULo1BIQ1rT17/lvHitPo7+hZOoF6VGl/90MzVGcwXbC2sURt1SzpAUX3o+ScGr61v+QWiIh5ZhHbIe+88VU/9AFm83Jo/aLpA/QSz7biLjnKkvF/S82QGoU36aPpTcSKZvRHWg/whW3TOJwtoIzVyUHIICf9IkrXqtr4DSEUaz3dmevQGGQnB1IyX5DFJw== gitlab@basile.local"
}
