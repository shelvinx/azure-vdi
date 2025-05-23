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

