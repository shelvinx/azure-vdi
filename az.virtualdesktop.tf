# az.vdi.tf

# AVD Host Pool
module "avd_host_pool" {
  source  = "Azure/avm-res-desktopvirtualization-hostpool/azurerm"
  version = "0.3.0"

  resource_group_name = module.resource_group.name

  virtual_desktop_host_pool_location                 = var.location
  virtual_desktop_host_pool_name                     = module.naming.virtual_desktop_host_pool.name
  virtual_desktop_host_pool_resource_group_name      = module.resource_group.name
  virtual_desktop_host_pool_load_balancer_type       = "BreadthFirst"
  virtual_desktop_host_pool_type                     = "Pooled"
  virtual_desktop_host_pool_maximum_sessions_allowed = 5
  virtual_desktop_host_pool_custom_rdp_properties = join(";", [
    "drivestoredirect:s:*",
    "audiomode:i:0", # 0 = No audio, 1 = Shared audio, 2 = Exclusive audio
    "videoplaybackmode:i:1",
    "redirectclipboard:i:1",
    "redirectcomports:i:1",
    "enablecredsspsupport:i:1",
    "use multimon:i:1",
    "targetisaadjoined:i:1",
    "enablerdsaadauth:i:1" # Required for Entra SSO
  ])

  tags = var.tags
}

# AVD Workspace
module "avd_workspace" {
  source  = "Azure/avm-res-desktopvirtualization-workspace/azurerm"
  version = "0.2.0"

  resource_group_name = module.resource_group.name

  virtual_desktop_workspace_location            = var.location
  virtual_desktop_workspace_name                = module.naming.virtual_desktop_workspace.name
  virtual_desktop_workspace_resource_group_name = module.resource_group.name

  tags = var.tags
}

# AVD Application Group for Desktop
module "avd_application_group" {
  source  = "Azure/avm-res-desktopvirtualization-applicationgroup/azurerm"
  version = "0.2.1"

  virtual_desktop_application_group_host_pool_id        = module.avd_host_pool.resource.id
  virtual_desktop_application_group_location            = var.location
  virtual_desktop_application_group_name                = module.naming.virtual_desktop_application_group.name
  virtual_desktop_application_group_resource_group_name = module.resource_group.name
  virtual_desktop_application_group_type                = "Desktop"

  role_assignments = {
    avd_users = {
      role_definition_id_or_name = "Desktop Virtualization User"
      principal_id               = data.azuread_group.avd_users.object_id
    }
    avd_admins = {
      role_definition_id_or_name = "Desktop Virtualization User"
      principal_id               = data.azuread_group.avd_admins.object_id
    }
  }
}

# Assign Desktop Application Group to Workspace
resource "azurerm_virtual_desktop_workspace_application_group_association" "workspace_assignment" {
  workspace_id         = module.avd_workspace.resource.id
  application_group_id = module.avd_application_group.resource.id
}

# AVD Host Pool Registration Info
resource "azurerm_virtual_desktop_host_pool_registration_info" "registration" {
  hostpool_id     = module.avd_host_pool.resource.id
  expiration_date = timeadd(timestamp(), "12h") # 12 hour expiry

  depends_on = [
    module.avd_host_pool
  ]
}
