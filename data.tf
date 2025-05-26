# data.tf
# Azure Resource References
data "azurerm_user_assigned_identity" "uai_tfvm" {
  name                = "uai-tfvm"
  resource_group_name = "rg-platform"
}

# AD Groups - AVD Admins
data "azuread_group" "avd_admins" {
  display_name = "AVD Admins"
}

# AD Groups - AVD Users
data "azuread_group" "avd_users" {
  display_name = "AVD Users"
}

# Storage Account Key for FSLogix configuration
data "azurerm_storage_account" "fslogix" {
  name                = module.fslogix_storage.name
  resource_group_name = module.resource_group.name
  depends_on          = [module.fslogix_storage]
}