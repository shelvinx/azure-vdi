# data.tf
# Azure Resource References
data "azurerm_user_assigned_identity" "uai_tfvm" {
  name                = "uai-tfvm"
  resource_group_name = "rg-platform"
}

data "azuread_group" "avd_admins" {
  display_name = "AVD Admins"
}

data "azuread_group" "avd_users" {
  display_name = "AVD Users"
}