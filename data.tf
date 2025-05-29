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

# Entra ID VNET
data "azurerm_virtual_network" "vnet_entra" {
  name                = "vnet-entra"
  resource_group_name = "rg-entradomain"
}