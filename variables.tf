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

# FSLogix-specific variables
variable "fslogix_profile_quota_gb" {
  type        = number
  default     = 100
  description = "Quota in GB for FSLogix profile file share"

  validation {
    condition     = var.fslogix_profile_quota_gb >= 10 && var.fslogix_profile_quota_gb <= 5120
    error_message = "FSLogix profile quota must be between 10 GB and 5120 GB."
  }
}

variable "fslogix_office_quota_gb" {
  type        = number
  default     = 100
  description = "Quota in GB for FSLogix office file share"

  validation {
    condition     = var.fslogix_office_quota_gb >= 10 && var.fslogix_office_quota_gb <= 5120
    error_message = "FSLogix office quota must be between 10 GB and 5120 GB."
  }
}

variable "fslogix_storage_tier" {
  type        = string
  default     = "Premium"
  description = "Storage tier for FSLogix storage account"

  validation {
    condition     = contains(["Standard", "Premium"], var.fslogix_storage_tier)
    error_message = "FSLogix storage tier must be either Standard or Premium."
  }
}

variable "fslogix_replication_type" {
  type    = string
  default = "LRS"

  validation {
    condition     = contains(["LRS", "ZRS", "GRS"], var.fslogix_replication_type)
    error_message = "FSLogix replication type must be LRS, ZRS, or GRS."
  }
}