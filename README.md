# Azure Virtual Desktop (AVD) Terraform Deployment

This project contains Terraform configurations to deploy and manage Azure Virtual Desktop (AVD) infrastructure. The infrastructure is provisioned using Infrastructure as Code (IaC) principles with Terraform, and state is managed in Terraform Cloud.

## Features

- Automated deployment of AVD host pools, application groups, and workspaces
- Integration with Azure Active Directory (Azure AD)
- Network configuration including virtual networks and subnets
- Managed disk and storage configuration
- Custom VM configurations and extensions

## Prerequisites

- Terraform Service Principal requires API Application Permissions to read Entra ID [docs](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/group)

## Configuration

This project uses the following Terraform providers:

- **azurerm**: For deploying Azure resources
- **random**: For generating random values when needed
- **azuread**: For Azure AD integration

The state is managed in Terraform Cloud in the "az-env" organization and "az-vdi" workspace.

## Notes
- `"aadJoin": true` is required for Entra ID integration; this feature is currently in preview. Note: Entra Joined Device needs to be deleted if re-deploying after destroy; as it causes issues with re-provisioning.
- Recommend updating extension settings with MDM Settings for Production Environment
- AVD Agent is configured using DSC
- Scale using the `windows_vm_count` variable, no additional changes required or add auto scaling plan configuration
- Web Client URL [https://client.wvd.microsoft.com/arm/webclient/index.html](https://client.wvd.microsoft.com/arm/webclient/index.html)

## File Structure

- `main.tf`: Core infrastructure configuration
- `az.iam.tf`: Role Assignments
- `az.network.tf`: VNET and Subnet configuration
- `variables.tf`: Variable declarations
- `az.virtualdesktop.tf`: AVD-specific resources
- `az.vm-windows.tf`: Windows VM configurations
- `data.tf`: Data sources used in the configuration
- `locals.tf`: for_each loop configuration

## Issues
- Currently has a Public IP associated with NIC due to issues with connectivity.
- VM Extensions dependancy provision_after_extensions issue - [https://github.com/hashicorp/terraform-provider-azurerm/issues/25423](https://github.com/hashicorp/terraform-provider-azurerm/issues/25423) - Use `depends_on` with the Terraform extension resource resolves the issue.