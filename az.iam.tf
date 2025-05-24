# Role assignment for Entra ID join - Allows the VM to join Entra ID
resource "azurerm_role_assignment" "entra_join" {
  for_each = local.windows_vm_instances

  scope                = module.resource_group.resource.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = module.windows_vm[each.key].system_assigned_mi_principal_id
  description          = "Allows VM to join Entra ID (Azure AD)"
}

# Role assignment for AVD registration - Allows the VM to register with the host pool
resource "azurerm_role_assignment" "avd_registration" {
  for_each = local.windows_vm_instances

  scope                = module.avd_host_pool.resource.id
  role_definition_name = "Desktop Virtualization Session Host Contributor"
  principal_id         = module.windows_vm[each.key].system_assigned_mi_principal_id
  description          = "Allows VM to register with AVD host pool"
}
