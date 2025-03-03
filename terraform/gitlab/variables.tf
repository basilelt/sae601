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

variable "ssh_public_keys" {
  description = "SSH public keys to add to the VM via cloud-init"
  type        = string
  sensitive   = true
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for VM connection"
  type        = string
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

variable "template_name" {
  description = "Name or ID of the Proxmox VM template to clone from"
  type        = string
}
