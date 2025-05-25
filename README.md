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
- Using Entra ID without Intune MDM requires the following registry key:
  ```powershell
  New-Item -Path HKLM:\SOFTWARE\Microsoft\RDInfraAgent\AADJPrivate
  ```
- AVD Agent is configured using DSC

## File Structure

- `main.tf`: Core infrastructure configuration
- `variables.tf`: Variable declarations
- `outputs.tf`: Output values for the deployment
- `az.virtualdesktop.tf`: AVD-specific resources
- `az.vm-windows.tf`: Windows VM configurations
- `data.tf`: Data sources used in the configuration

## Issues
- Currently has a Public IP associated with NIC due to issues with connectivity.