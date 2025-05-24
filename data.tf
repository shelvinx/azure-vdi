data "azurerm_user_assigned_identity" "uai_tfvm" {
  name                = "uai-tfvm"
  resource_group_name = "rg-platform"
}
