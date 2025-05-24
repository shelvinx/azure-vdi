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