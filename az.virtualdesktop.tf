# az.vdi.tf

# AVD Host Pool
module "avd_host_pool" {
  source  = "Azure/avm-res-desktopvirtualization-hostpool/azurerm"
  version = "0.3.0"

  resource_group_name = module.resource_group.name

  virtual_desktop_host_pool_location            = var.location
  virtual_desktop_host_pool_load_balancer_type  = "BreadthFirst"
  virtual_desktop_host_pool_type                = "Pooled"
  virtual_desktop_host_pool_name                = module.naming.virtual_desktop_host_pool.name
  virtual_desktop_host_pool_resource_group_name = module.resource_group.name

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
}

# AVD Host Pool Registration Info
resource "azurerm_virtual_desktop_host_pool_registration_info" "registration" {
  hostpool_id     = module.avd_host_pool.resource.id
  expiration_date = timeadd(timestamp(), "12h") # 12 hour expiry

  depends_on = [
    module.avd_host_pool
  ]
}
