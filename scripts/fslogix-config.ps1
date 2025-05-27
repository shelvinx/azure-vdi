# Simplified FSLogix Configuration Script (FSLogix already installed on AVD image)
param(
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $false)]
    [string]$ProfileShare = "profiles",
    
    [Parameter(Mandatory = $false)]
    [string]$OfficeShare = "office-containers"
)

$ErrorActionPreference = 'Stop'

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
    Write-Output "Set $Path\$Name = $Value"
}

try {
    Write-Output "Configuring FSLogix for Azure AD authentication..."
    
    # Configure Azure AD Kerberos authentication
    $kerberosRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
    Set-RegistryValue -Path $kerberosRegPath -Name "CloudKerberosTicketRetrievalEnabled" -Value 1
    
    # FSLogix Profile Container Settings
    $fslogixRegPath = "HKLM:\SOFTWARE\FSLogix\Profiles"
    
    Set-RegistryValue -Path $fslogixRegPath -Name "Enabled" -Value 1
    
    $profileUNC = "\\$StorageAccountName.file.core.windows.net\$ProfileShare"
    Set-RegistryValue -Path $fslogixRegPath -Name "VHDLocations" -Value $profileUNC -Type "String"
    
    Set-RegistryValue -Path $fslogixRegPath -Name "SizeInMBs" -Value 30720
    Set-RegistryValue -Path $fslogixRegPath -Name "IsDynamic" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "VolumeType" -Value "1"
    Set-RegistryValue -Path $fslogixRegPath -Name "FlipFlopProfileDirectoryName" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "AccessNetworkAsComputerObject" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1
    
    # Office Container Settings
    $officeRegPath = "HKLM:\SOFTWARE\Policies\FSLogix\ODFC"
    Set-RegistryValue -Path $officeRegPath -Name "Enabled" -Value 1
    
    $officeUNC = "\\$StorageAccountName.file.core.windows.net\$OfficeShare"
    Set-RegistryValue -Path $officeRegPath -Name "VHDLocations" -Value $officeUNC -Type "String"
    Set-RegistryValue -Path $officeRegPath -Name "SizeInMBs" -Value 10240
    Set-RegistryValue -Path $officeRegPath -Name "IsDynamic" -Value 1
    Set-RegistryValue -Path $officeRegPath -Name "VolumeType" -Value "1"
    Set-RegistryValue -Path $officeRegPath -Name "AccessNetworkAsComputerObject" -Value 1
    
    
} catch {
    Write-Error "FSLogix configuration failed: $($_.Exception.Message)"
    throw
}