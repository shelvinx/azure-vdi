# AVM Virtual Machine
module "windows_vm" {
  for_each = local.windows_vm_instances
  source   = "Azure/avm-res-compute-virtualmachine/azurerm"
  version  = "0.19.0"

  location                   = var.location
  resource_group_name        = module.resource_group.name
  name                       = "${module.naming.virtual_machine.name}-${each.key}"
  os_type                    = "Windows"
  sku_size                   = var.sku_size
  zone                       = null
  encryption_at_host_enabled = false

  account_credentials = {
    admin_credentials = {
      username                           = "azureuser"
      password                           = var.admin_password
      generate_admin_password_or_ssh_key = false
    }
  }


  os_disk = {
    name                 = "${module.naming.managed_disk.name}-${each.key}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference = {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-11"
    sku       = "win11-24h2-avd"
    version   = "latest"
  }

  network_interfaces = {
    network_interface_1 = {
      name = "${module.naming.network_interface.name}-${each.key}"
      ip_configurations = {
        ip_configurations_1 = {
          name                          = "ipconfig-${each.key}"
          private_ip_subnet_resource_id = module.avd_vnet.subnets.avd_subnet.resource_id
          public_ip_address_resource_id = module.host_public_ip[each.key].resource_id
        }
      }
    }
  }

  managed_identities = {
    system_assigned            = true                                              # Required for Entra ID join
    user_assigned_resource_ids = [data.azurerm_user_assigned_identity.uai_tfvm.id] # Use to access Key Vault
  }

  priority        = var.priority
  max_bid_price   = var.spot_max_price
  eviction_policy = var.eviction_policy

  extensions = {
    # Entra ID Join Extension
    AADLogin = {
      name                       = "AADLoginForWindows"
      publisher                  = "Microsoft.Azure.ActiveDirectory"
      type                       = "AADLoginForWindows"
      type_handler_version       = "2.2"
      auto_upgrade_minor_version = true

      depends_on = ["AVDRegistration"]
    },
    # AVD Agent Extension
    AVDRegistration = {
      name                       = "AVD-DSC-Configuration"
      publisher                  = "Microsoft.Powershell"
      type                       = "DSC"
      type_handler_version       = "2.77"
      auto_upgrade_minor_version = true

      settings = <<-SETTINGS
          {
            "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip",
            "configurationFunction": "Configuration.ps1\\AddSessionHost",
            "properties": {
              "HostPoolName":"${module.avd_host_pool.resource.name}",
              "aadJoin": true,
              "UseAgentDownloadEndpoint": true,
              "aadJoinPreview": false,
              "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.registration.token}"
            }
          }
      SETTINGS
    },
    # AVD VM Config
    # VM Configuration Extension
    vm_config = {
      name                       = "ConfigurationScript"
      publisher                  = "Microsoft.Compute"
      type                       = "CustomScriptExtension"
      type_handler_version       = "1.10"
      auto_upgrade_minor_version = true

      settings = <<SETTINGS
      {
        "fileUris": [
          "https://raw.githubusercontent.com/shelvinx/azure-vdi/refs/heads/main/scripts/avd-config.ps1"
        ],
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -File avd-config.ps1"
      }
      SETTINGS
    },
    # Key Vault Configuration Extension
    keyvault = {
      name                       = "KeyVaultForWindows-${each.key}" # Unique name per VM
      publisher                  = "Microsoft.Azure.KeyVault"
      type                       = "KeyVaultForWindows"
      type_handler_version       = "3.0" # Using a common version
      auto_upgrade_minor_version = true
      settings = jsonencode({
        secretsManagementSettings = {
          pollingIntervalInS       = "60"
          certificateStoreName     = "My"  # Standard Windows certificate store
          linkOnRenewal            = false # Set to true if needed
          certificateStoreLocation = "LocalMachine"
          observedCertificates = [
            # Dynamically construct the Key Vault secret URI for the certificate
            "https://${var.key_vault_name}.vault.azure.net/secrets/${each.key}-cert"
          ]
        }
        # Authentication using the VM's User Assigned Managed Identity
        authenticationSettings = {
          msiEndpoint = "http://169.254.169.254/metadata/identity"
          # Use the client ID of the assigned identity
          msiClientId = data.azurerm_user_assigned_identity.uai_tfvm.client_id
        }
      })
      # No protected_settings needed when using Managed Identity
    }
  }

  tags = var.tags
}