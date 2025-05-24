variable "HCP_CLIENT_ID" {
  description = "HCP Client ID"
  type        = string
  sensitive   = true
}

variable "HCP_CLIENT_SECRET" {
  description = "HCP Client Secret"
  type        = string
  sensitive   = true
}

variable "key_vault_name" {
  description = "Key Vault name"
  type        = string
  sensitive   = true
}

variable "location" {
  type    = string
  default = "uksouth"
}

variable "tags" {
  type = map(string)
  default = {
    "Deployment"    = "Terraform"
    "Configuration" = "Ansible"
  }
}

variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Retrieved from HCP Vault"
}

variable "windows_vm_count" {
  type        = number
  description = "Number of Windows VMs to create"
}

variable "spot_max_price" {
  type        = number
  description = "Maximum price for spot instances"
}

variable "eviction_policy" {
  type        = string
  description = "Eviction policy for spot instances"
}

variable "priority" {
  type        = string
  description = "Priority for spot instances"

  validation {
    condition     = var.priority == "Spot" || var.priority == "Regular"
    error_message = "Priority must be Spot or Regular"
  }
}

variable "sku_size" {
  type        = string
  description = "SKU size for the VM"
}