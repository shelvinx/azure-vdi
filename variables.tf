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

variable "existing_vnet_name" {
  type        = string
  description = "The name of the existing Virtual Network."
  default     = "vnet-spoke"
}

variable "existing_vnet_resource_group_name" {
  type        = string
  description = "The name of the resource group where the existing Virtual Network resides."
  default     = "rg-platform"
}

variable "existing_subnet_name" {
  type        = string
  description = "The name of the existing subnet within the Virtual Network."
  default     = "default"
}