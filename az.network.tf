# az.network.tf
# AVD VNET
module "avd_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  name                = module.naming.virtual_network.name
  location            = var.location
  resource_group_name = module.resource_group.name

  address_space = ["10.0.0.0/16"]

  subnets = {
    avd_subnet = {
      name                                           = module.naming.subnet.name
      address_prefix                                 = "10.0.0.0/24"
      service_endpoints                              = ["Microsoft.Storage"]
      private_endpoint_network_policies              = "NetworkSecurityGroupEnabled"
      private_link_service_network_policies_enabled  = true
      network_security_group = {
        id = module.avd_nsg.resource_id
      }
    }
  }

  tags = var.tags
}

# AVD Network Security Group and Rules
module "avd_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.4.0"

  name                = module.naming.network_security_group.name
  location            = var.location
  resource_group_name = module.resource_group.name

  security_rules = {
    AllowRDP = {
      name                       = "AllowRDP"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "3389"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    AllowHTTPS = {
      name                       = "AllowHTTPS"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
    AllowICMP = {
      name                       = "AllowICMP"
      priority                   = 130
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Icmp"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  tags = var.tags
}

# Session Host Public IP
module "host_public_ip" {
  for_each = local.windows_vm_instances
  source   = "Azure/avm-res-network-publicipaddress/azurerm"
  version  = "0.2.0"

  location            = var.location
  resource_group_name = module.resource_group.name
  name                = "${module.naming.public_ip.name}-${each.key}"

  tags = var.tags
}