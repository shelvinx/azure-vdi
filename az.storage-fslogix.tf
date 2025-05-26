# az.storage.tf
# FSLogix Storage Account for User Profiles

module "fslogix_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.2"

  name                = "stauraavdfslogix"  # Use your existing naming convention
  location            = var.location
  resource_group_name = module.resource_group.name

  account_kind             = "StorageV2"
  account_tier             = "Premium"
  account_replication_type = "LRS" # Use ZRS for production
  access_tier              = "Hot"

  # Enable features for FSLogix with Azure AD authentication
  min_tls_version                         = "TLS1_2"
  shared_access_key_enabled               = false  # Disable key-based auth
  infrastructure_encryption_enabled       = true
  allow_nested_items_to_be_public         = false
  cross_tenant_replication_enabled        = false

  azure_files_authentication = {
    directory_type = "AADKERB"
  }
  
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
    }
    office_containers = {
      name  = "office-containers"
      quota = var.fslogix_office_quota_gb
    }
  }

  # RBAC assignments for AVD VMs and Azure AD authentication
  role_assignments = {
    # System assigned identities for VMs
    vm_storage_contributor = {
      role_definition_id_or_name = "Storage File Data SMB Share Contributor"
      principal_id               = module.windows_vm["vm1"].system_assigned_mi_principal_id
    }
    # User groups for file access
    fslogix_users_contributor = {
      role_definition_id_or_name = "Storage File Data SMB Share Contributor"
      principal_id               = data.azuread_group.avd_users.object_id
    }
    fslogix_admins_elevated = {
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
      autoregistration = false
    }
  }

  tags = var.tags
}

# Additional RBAC for multiple VMs (dynamic assignment)
resource "azurerm_role_assignment" "vm_fslogix_access" {
  for_each = local.windows_vm_instances

  scope                = module.fslogix_storage.resource_id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = module.windows_vm[each.key].system_assigned_mi_principal_id
  description          = "Allows VM ${each.key} to access FSLogix storage"
}

# Storage Account data source (no longer needs access key)
data "azurerm_storage_account" "fslogix" {
  name                = module.fslogix_storage.name
  resource_group_name = module.resource_group.name
  depends_on          = [module.fslogix_storage]
}