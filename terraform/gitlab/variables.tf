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
  description = "Network bridge to attach the VM to"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Static IP address for the VM"
  type        = string
}

variable "gateway_ip" {
  description = "Gateway IP address"
  type        = string
}

variable "nameserver" {
  description = "DNS server addresses"
  type        = list(string)
  default     = ["1.1.1.1", "8.8.8.8"]
}

variable "template_vm_id" {
  description = "ID of the template VM to clone"
  type        = number
}

variable "gitlab_vm_id" {
  description = "ID to assign to the GitLab VM"
  type        = number
  default     = null
}

