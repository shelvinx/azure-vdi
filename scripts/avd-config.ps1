# Check and switch network profile from Public to Private
try {
Get-NetConnectionProfile |
  Where-Object NetworkCategory -Eq 'Public' |
  ForEach-Object {
    Set-NetConnectionProfile -InterfaceIndex $_.InterfaceIndex -NetworkCategory Private
    Write-Output "Changed network profile on interface '$($_.InterfaceAlias)' to Private."
  }
}
catch {
    Write-Error "Failed to change network profile:" $_.Exception.Message
}

# Enable PS Remoting with simple error handling
try {
    Enable-PSRemoting -Force -ErrorAction Stop
    Write-Output "PS Remoting enabled successfully."
}
catch {
    Write-Error "Failed to enable PS Remoting:" $_.Exception.Message
}

# Create self signed certificate
try {
$certParams = @{
    CertStoreLocation = 'Cert:\LocalMachine\My'
    DnsName           = $env:COMPUTERNAME
    NotAfter          = (Get-Date).AddYears(1)
    Provider          = 'Microsoft Software Key Storage Provider'
    Subject           = "CN=$env:COMPUTERNAME"
}
$cert = New-SelfSignedCertificate @certParams
Write-Output "Self-signed certificate created successfully."
}
catch {
    Write-Error "Failed to create self-signed certificate:" $_.Exception.Message
}

# Create HTTPS listener
try {
$httpsParams = @{
    ResourceURI = 'winrm/config/listener'
    SelectorSet = @{
        Transport = "HTTPS"
        Address   = "*"
    }
    ValueSet = @{
        CertificateThumbprint = $cert.Thumbprint
        Enabled               = $true
    }
}
New-WSManInstance @httpsParams
Write-Output "HTTPS listener created successfully."
}
catch {
    Write-Error "Failed to create HTTPS listener:" $_.Exception.Message
}

try {
# Opens port 5986 for all profiles
$firewallParams = @{
    Action      = 'Allow'
    Description = 'Inbound rule for Windows Remote Management via WS-Management. [TCP 5986]'
    Direction   = 'Inbound'
    DisplayName = 'Windows Remote Management (HTTPS-In)'
    LocalPort   = 5986
    Profile     = 'Any'
    Protocol    = 'TCP'
}
New-NetFirewallRule @firewallParams
Write-Output "Firewall rule for HTTPS listener created successfully."
}
catch {
    Write-Error "Failed to create firewall rule:" $_.Exception.Message
}

try {
# Enable HTTP traffic on port 80
$firewallParamsHttp = @{
    Action      = 'Allow'
    Description = 'Inbound rule for HTTP traffic. [TCP 80]'
    Direction   = 'Inbound'
    DisplayName = 'HTTP (TCP 80)'
    LocalPort   = 80
    Profile     = 'Any'
    Protocol    = 'TCP'
}
New-NetFirewallRule @firewallParamsHttp
Write-Output "Firewall rule for HTTP (port 80) created successfully."
}
catch {
    Write-Error "Failed to create HTTP firewall rule:" $_.Exception.Message
}

# Function for registry modifications
function Set-RegistryDword {
    param (
        [string]$Path,
        [string]$Name,
        [int]$Value
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type DWord
        Write-Output "Set $Name in $Path successfully."
    }
    catch {
        Write-Error "Failed to set $Name in $Path : $($_.Exception.Message)"
    }
}

# Registry modifications (looped for maintainability)
$registrySettings = @(
    @{
        Path  = "HKLM:\SYSTEM\CurrentControlSet\Control\Network"
        Name  = "NewNetworkWindowOff"
        Value = 1
    }
)


foreach ($setting in $registrySettings) {
    Set-RegistryDword -Path $setting.Path -Name $setting.Name -Value $setting.Value
}

# Install Chocolatey
try {
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Output "Chocolatey installed successfully."
}
catch {
    Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
}

# Set registry key for Entra ID join
try {
    if (-not (Test-Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent\AADJPrivate")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\RDInfraAgent\AADJPrivate" -Force | Out-Null
        Write-Output "Entra ID join registry key created successfully."
    }
    else {
        Write-Output "Entra ID join registry key already exists."
    }
}
catch {
    Write-Error "Failed to set Entra ID join registry key: $($_.Exception.Message)"
}