# Role assignment for Entra ID join - Allows the VM to join Entra ID
resource "azurerm_role_assignment" "entra_join" {
  for_each = local.windows_vm_instances

  scope                = module.resource_group.resource.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = module.windows_vm[each.key].system_assigned_mi_principal_id
  description          = "Allows VM to join Entra ID (Azure AD)"
}

resource "azurerm_role_assignment" "vm_admin_login" {
  for_each = local.windows_vm_instances

  scope                = module.windows_vm[each.key].resource_id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = data.azuread_group.avd_admins.object_id
  description          = "Allows VM to login as an admin"
}

resource "azurerm_role_assignment" "vm_user_login" {
  for_each = local.windows_vm_instances

  scope                = module.windows_vm[each.key].resource_id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = data.azuread_group.avd_users.object_id
  description          = "Allows VM to login as a user"
}

# Role assignment for AVD registration - Allows the VM to register with the host pool
resource "azurerm_role_assignment" "avd_registration" {
  for_each = local.windows_vm_instances

  scope                = module.avd_host_pool.resource.id
  role_definition_name = "Desktop Virtualization Host Pool Contributor"
  principal_id         = module.windows_vm[each.key].system_assigned_mi_principal_id
  description          = "Allows VM to register with AVD host pool"
}

# Role assignment for FSLogix access - Allows the VM to access FSLogix storage
resource "azurerm_role_assignment" "fslogix_access" {
  for_each = local.windows_vm_instances

  scope                = module.fslogix_storage.resource_id
  role_definition_name = "Storage File Data SMB Share Elevated Contributor"
  principal_id         = module.windows_vm[each.key].system_assigned_mi_principal_id
  description          = "Allows VM to access FSLogix storage"

  depends_on = [module.fslogix_storage]
}
