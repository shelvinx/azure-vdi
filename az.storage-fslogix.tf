# az.storage-fslogix.tf
# FSLogix Storage Account for User Profiles

# Storage Account for FSLogix profiles
module "fslogix_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.2"

  name                = module.naming.storage_account.name
  location            = var.location
  resource_group_name = module.resource_group.name

  account_kind             = "StorageV2"
  account_tier             = "Premium"
  account_replication_type = "LRS"
  access_tier              = "Hot"

  # Enable features for FSLogix
  min_tls_version          = "TLS1_2"
  
  # Network access rules
  network_rules = {
    default_action = "Deny"
    ip_rules       = [] # Add your admin IPs here if needed
    virtual_network_subnet_ids = [
      module.avd_vnet.subnets.avd_subnet.resource_id
    ]
    bypass = ["AzureServices"]
  }

  # Private endpoint for secure access
  private_endpoints = {
    pe_file = {
      name                          = "${module.naming.private_endpoint.name}-fslogix-file"
      subnet_resource_id            = module.avd_vnet.subnets.avd_subnet.resource_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = [module.private_dns_zone_file.resource_id]
    }
  }

  # File shares for FSLogix
  containers = {
    profiles = {
      name  = "profiles"
      quota = var.fslogix_profile_quota_gb
      metadata = {
        purpose = "FSLogix User Profiles"
      }
    }
    office_containers = {
      name  = "office-containers"
      quota = var.fslogix_office_quota_gb
      metadata = {
        purpose = "FSLogix Office Containers"
      }
    }
  }

  # RBAC assignments for AVD VMs
  role_assignments = {
    fslogix_contributor = {
      role_definition_id_or_name = "Storage File Data SMB Share Contributor"
      principal_id               = data.azuread_group.avd_users.object_id
    }
    fslogix_elevated_contributor = {
      role_definition_id_or_name = "Storage File Data SMB Share Elevated Contributor"
      principal_id               = data.azuread_group.avd_admins.object_id
    }
  }

  tags = merge(var.tags, {
    Purpose = "FSLogix-Profiles"
  })
}

# Private DNS Zone for File Storage
module "private_dns_zone_file" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.3.3"

  domain_name         = "privatelink.file.core.windows.net"
  resource_group_name = module.resource_group.name

  virtual_network_links = {
    avd_vnet_link = {
      vnetlinkname     = "fslogix-file-dns-link"
      vnetid           = module.avd_vnet.resource_id
      autoregistration = true
    }
  }

  tags = var.tags
}