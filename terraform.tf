# terraform.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.30.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }

  # terraform cloud
  cloud {
    organization = "az-env"
    workspaces {
      name = "az-vdi"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  resource_provider_registrations = "extended"
}

provider "azuread" {
  tenant_id = "68c917de-20e3-4751-9ccc-cbbe32e11325"
}
