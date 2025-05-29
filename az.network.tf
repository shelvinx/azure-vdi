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

# Private DNS Zone for File Storage
module "private_dns_zone_file" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.3.3"

  domain_name         = "privatelink.file.core.windows.net"
  resource_group_name = module.resource_group.name

  virtual_network_links = {
    avd_vnet_link = {
      vnetlinkname     = "fslogix-file-dns-link"
      vnetid           = module.avd_vnet.resource_id
      autoregistration = false
    }
  }
}

# VNET Peering from AVD to Entra Domain VNET
module "avd-entradomain-peering" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "0.8.1"

  name                = module.naming.virtual_network_peering.name

  virtual_network = module.avd_vnet.resource_id
  remote_virtual_network = data.azurerm_virtual_network.vnet_entra.resource_id
}

resource "azurerm_virtual_network_dns_servers" "avd_dns" {
  virtual_network_id = module.avd_vnet.virtual_network_id
  dns_servers       = ["10.2.0.4", "10.2.0.5"]
}