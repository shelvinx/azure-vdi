# az.storage.tf
# FSLogix Storage Account for User Profiles

module "fslogix_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.6.2"

  name                = "stauraavdfslogix"  # Use your existing naming convention
  location            = var.location
  resource_group_name = module.resource_group.name

  account_kind             = "FileStorage" # For Azure Files
  account_tier             = "Premium" # Recommended for FSLogix
  account_replication_type = "LRS" # Use ZRS for production

  # Enable features for FSLogix with Azure AD authentication
  min_tls_version                         = "TLS1_2"
  shared_access_key_enabled               = true  # This is required, otherwise key-based errors will occur.
  infrastructure_encryption_enabled       = true
  allow_nested_items_to_be_public         = false
  cross_tenant_replication_enabled        = false

  # Entra ID Authentication (Kerberos)
  azure_files_authentication = {
    directory_type = "AADKERB"
  }
  
  # Network access rules
  network_rules = {
    default_action = "Allow"
    bypass = ["AzureServices"]
  }

  # File shares for FSLogix
  shares = {
    profiles = {
      name  = "profiles"
      quota = var.fslogix_profile_quota_gb
      access_tier = "Premium"
    }
  }

  share_properties = {
    profiles = {
      SMB = {
        authentication_types = "Kerberos"
      }
    }
  }

  # RBAC assignments for AVD VMs and Azure AD authentication
  role_assignments = {
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

# Storage Account data source (no longer needs access key)
data "azurerm_storage_account" "fslogix" {
  name                = module.fslogix_storage.name
  resource_group_name = module.resource_group.name
  depends_on          = [module.fslogix_storage]
}