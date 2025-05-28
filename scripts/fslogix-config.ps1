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
    
    # Set all FSLogix profile settings
    $profileUNC = "\\$StorageAccountName.file.core.windows.net\$ProfileShare"
    
    # Required settings
    Set-RegistryValue -Path $fslogixRegPath -Name "Enabled" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "VHDLocations" -Value $profileUNC -Type "String"
    
    # Performance and reliability settings
    Set-RegistryValue -Path $fslogixRegPath -Name "SizeInMBs" -Value 30000
    Set-RegistryValue -Path $fslogixRegPath -Name "VolumeType" -Value "VHDX" -Type "String"
    Set-RegistryValue -Path $fslogixRegPath -Name "IsDynamic" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "ProfileType" -Value 0
    
    # Profile management settings
    Set-RegistryValue -Path $fslogixRegPath -Name "FlipFlopProfileDirectoryName" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1
   
    # Lock retry settings
    Set-RegistryValue -Path $fslogixRegPath -Name "LockedRetryCount" -Value 3
    Set-RegistryValue -Path $fslogixRegPath -Name "LockedRetryInterval" -Value 15
    
    # Reattach settings
    Set-RegistryValue -Path $fslogixRegPath -Name "ReAttachIntervalSeconds" -Value 15
    Set-RegistryValue -Path $fslogixRegPath -Name "ReAttachRetryCount" -Value 3

} catch {
    Write-Error "FSLogix configuration failed: $($_.Exception.Message)"
    throw
}