# main.tf
# Contains the primary resources for Azure
# AVM Naming Module
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = ["aura", "avd"]
}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"

  name     = module.naming.resource_group.name
  location = var.location

  tags = var.tags
}