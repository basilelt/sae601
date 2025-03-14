variable "proxmox_api_url" {
  description = "URL of the Proxmox API"
  type        = string
}

variable "proxmox_api_token" {
  description = "API token for Proxmox authentication"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Whether to skip TLS verification for the Proxmox API"
  type        = bool
  default     = false
}

variable "proxmox_node" {
  description = "Name of the Proxmox node"
  type        = string
}

variable "ssh_public_keys" {
  description = "SSH public key to add to authorized_keys"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key for provisioning"
  type        = string
}

variable "storage_pool" {
  description = "ID of the storage pool to use"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge to attach the container to"
  type        = string
  default     = "vmbr0"
}

variable "container_template_file_id" {
  description = "ID of the container template to use"
  type        = string
  default     = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
}

variable "dns_primary_ip" {
  description = "Static IP address for the primary DNS container"
  type        = string
}

variable "dns_secondary_ip" {
  description = "Static IP address for the secondary DNS container"
  type        = string
}

variable "gateway_ip" {
  description = "Gateway IP address"
  type        = string
}

variable "domain" {
  description = "Domain name"
  type        = string
}

variable "nameserver" {
  description = "DNS server addresses for container configuration"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "dns_primary_container_id" {
  description = "ID to assign to the primary DNS container"
  type        = number
  default     = 110
}

variable "dns_secondary_container_id" {
  description = "ID to assign to the secondary DNS container"
  type        = number
  default     = 111
}

variable "root_password" {
  description = "Root password for the containers"
  type        = string
  sensitive   = true
}
