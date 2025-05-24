# Azure Virtual Desktop (AVD) Terraform Deployment

This project contains Terraform configurations to deploy and manage Azure Virtual Desktop (AVD) infrastructure. Terraform Cloud is used for state management.

## Configuration

This project uses the following Terraform providers:

- **azurerm** (version 4.30.0): For deploying Azure resources
- **random** (version 3.7.2): For generating random values when needed

The state is managed in Terraform Cloud in the "az-env" organization and "az-vdi" workspace.