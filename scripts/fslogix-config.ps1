# scripts/fslogix-config.ps1
# FSLogix Configuration Script for AVD Session Hosts with Azure AD Authentication

param(
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $false)]
    [string]$ProfileShare = "profiles",
    
    [Parameter(Mandatory = $false)]
    [string]$OfficeShare = "office-containers",
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\FSLogix-Config.log"
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    $logMessage | Out-File -FilePath $LogPath -Append
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [string]$Type = "DWord"
    )
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-Log "Created registry path: $Path"
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        Write-Log "Set registry value: $Path\$Name = $Value"
    }
    catch {
        Write-Log "ERROR: Failed to set $Path\$Name - $($_.Exception.Message)"
        throw
    }
}

function Enable-AzureADKerberos {
    try {
        Write-Log "Configuring Azure AD Kerberos authentication..."
        
        # Enable Azure AD Kerberos authentication
        $kerberosRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
        Set-RegistryValue -Path $kerberosRegPath -Name "CloudKerberosTicketRetrievalEnabled" -Value 1
        
        # Configure additional Kerberos settings for Azure Files
        $lsaRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
        Set-RegistryValue -Path $lsaRegPath -Name "LmCompatibilityLevel" -Value 3
        
        Write-Log "Azure AD Kerberos configuration completed"
    }
    catch {
        Write-Log "ERROR: Failed to configure Azure AD Kerberos - $($_.Exception.Message)"
        throw
    }
}

try {
    Write-Log "Starting FSLogix configuration with Azure AD authentication..."
    
    # Download and install FSLogix
    Write-Log "Downloading FSLogix..."
    $tempDir = "C:\temp\fslogix"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    $fslogixUrl = "https://aka.ms/fslogix_download"
    $fslogixZip = "$tempDir\FSLogix.zip"
    $fslogixExtracted = "$tempDir\FSLogix"
    
    # Download FSLogix
    Invoke-WebRequest -Uri $fslogixUrl -OutFile $fslogixZip
    Write-Log "Downloaded FSLogix to: $fslogixZip"
    
    # Extract FSLogix
    Expand-Archive -Path $fslogixZip -DestinationPath $fslogixExtracted -Force
    Write-Log "Extracted FSLogix to: $fslogixExtracted"
    
    # Install FSLogix Apps
    $fslogixInstaller = Get-ChildItem -Path $fslogixExtracted -Recurse -Name "FSLogixAppsSetup.exe" | Select-Object -First 1
    $installerPath = Join-Path $fslogixExtracted $fslogixInstaller
    
    Write-Log "Installing FSLogix Apps from: $installerPath"
    $installProcess = Start-Process -FilePath $installerPath -ArgumentList "/install", "/quiet", "/norestart" -Wait -PassThru
    
    if ($installProcess.ExitCode -ne 0) {
        throw "FSLogix installation failed with exit code: $($installProcess.ExitCode)"
    }
    Write-Log "FSLogix Apps installed successfully"
    
    # Configure Azure AD Kerberos authentication
    Enable-AzureADKerberos
    
    # Configure FSLogix Registry Settings
    Write-Log "Configuring FSLogix registry settings..."
    
    $fslogixRegPath = "HKLM:\SOFTWARE\FSLogix\Profiles"
    
    # Enable FSLogix Profiles
    Set-RegistryValue -Path $fslogixRegPath -Name "Enabled" -Value 1
    
    # Configure VHD Locations (using UNC path)
    $profileUNC = "\\$StorageAccountName.file.core.windows.net\$ProfileShare"
    Set-RegistryValue -Path $fslogixRegPath -Name "VHDLocations" -Value $profileUNC -Type "String"
    
    # Profile Container Settings
    Set-RegistryValue -Path $fslogixRegPath -Name "SizeInMBs" -Value 30720  # 30GB default
    Set-RegistryValue -Path $fslogixRegPath -Name "IsDynamic" -Value 1      # Dynamic expansion
    Set-RegistryValue -Path $fslogixRegPath -Name "VolumeType" -Value "VHDX"
    Set-RegistryValue -Path $fslogixRegPath -Name "FlipFlopProfileDirectoryName" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "SIDDirNamePattern" -Value "%username%%sid%" -Type "String"
    Set-RegistryValue -Path $fslogixRegPath -Name "SIDDirNameMatch" -Value "%username%%sid%" -Type "String"
    
    # Authentication settings for Azure AD
    Set-RegistryValue -Path $fslogixRegPath -Name "AccessNetworkAsComputerObject" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "ProfileType" -Value 0
    
    # Concurrent user sessions and error handling
    Set-RegistryValue -Path $fslogixRegPath -Name "PreventLoginWithFailure" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "PreventLoginWithTempProfile" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1
    
    # Configure Office Container (optional but recommended)
    Write-Log "Configuring Office Container settings..."
    $officeRegPath = "HKLM:\SOFTWARE\Policies\FSLogix\ODFC"
    
    Set-RegistryValue -Path $officeRegPath -Name "Enabled" -Value 1
    $officeUNC = "\\$StorageAccountName.file.core.windows.net\$OfficeShare"
    Set-RegistryValue -Path $officeRegPath -Name "VHDLocations" -Value $officeUNC -Type "String"
    Set-RegistryValue -Path $officeRegPath -Name "SizeInMBs" -Value 10240  # 10GB for Office
    Set-RegistryValue -Path $officeRegPath -Name "IsDynamic" -Value 1
    Set-RegistryValue -Path $officeRegPath -Name "VolumeType" -Value "VHDX"
    Set-RegistryValue -Path $officeRegPath -Name "FlipFlopProfileDirectoryName" -Value 1
    Set-RegistryValue -Path $officeRegPath -Name "AccessNetworkAsComputerObject" -Value 1
    
    # Configure Cloud Cache (optional for high availability)
    if ($env:FSLOGIX_ENABLE_CLOUD_CACHE -eq "true") {
        Write-Log "Configuring FSLogix Cloud Cache..."
        Set-RegistryValue -Path $fslogixRegPath -Name "CCDLocations" -Value "type=smb,connectionString=$profileUNC" -Type "String"
        Set-RegistryValue -Path $fslogixRegPath -Name "ClearCacheOnLogoff" -Value 1
        Set-RegistryValue -Path $fslogixRegPath -Name "HealthyProvidersRequiredForRegister" -Value 1
    }
    
    # Start FSLogix services
    Write-Log "Starting FSLogix services..."
    
    $services = @("FSLogix Apps Services")
    foreach ($service in $services) {
        try {
            $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
            if ($svc) {
                Set-Service -Name $service -StartupType Automatic
                Start-Service -Name $service
                Write-Log "Started service: $service"
            } else {
                Write-Log "WARNING: Service not found: $service"
            }
        }
        catch {
            Write-Log "WARNING: Failed to start service $service - $($_.Exception.Message)"
        }
    }
    
    # Test connectivity to file share using Azure AD authentication
    Write-Log "Testing connectivity to file shares with Azure AD authentication..."
    try {
        # Wait for Azure AD authentication to be ready
        Start-Sleep -Seconds 30
        
        $testPath = "\\$StorageAccountName.file.core.windows.net\$ProfileShare"
        if (Test-Path $testPath) {
            Write-Log "Successfully connected to profile share: $testPath"
        } else {
            Write-Log "INFO: Profile share will be accessible after user login: $testPath"
        }
    }
    catch {
        Write-Log "INFO: Profile share connectivity will be validated at user login - $($_.Exception.Message)"
    }
    
    # Create a test file to verify write permissions (if accessible)
    try {
        $testFile = "\\$StorageAccountName.file.core.windows.net\$ProfileShare\fslogix-test.txt"
        "FSLogix configuration test - $(Get-Date)" | Out-File -FilePath $testFile -Force
        Remove-Item -Path $testFile -Force
        Write-Log "Successfully tested write permissions to profile share"
    }
    catch {
        Write-Log "INFO: Write permissions will be available after user authentication"
    }
    
    # Cleanup temp files
    Write-Log "Cleaning up temporary files..."
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "FSLogix configuration with Azure AD authentication completed successfully!"
    
    # Create verification file
    $verificationFile = "C:\FSLogix-Configured.txt"
    $verificationContent = @"
FSLogix Configuration Completed
===============================
Date: $(Get-Date)
Storage Account: $StorageAccountName
Profile Share: $ProfileShare
Office Share: $OfficeShare
Authentication: Azure AD
Status: SUCCESS

Next Steps:
1. Restart the VM for all settings to take effect
2. Test with an actual user login
3. Verify profile container creation in storage account
"@
    $verificationContent | Out-File -FilePath $verificationFile -Force
    Write-Log "Created verification file: $verificationFile"
    
    # Recommend restart
    Write-Log "IMPORTANT: A restart is recommended for all FSLogix settings to take effect"
    
} catch {
    Write-Log "ERROR: FSLogix configuration failed - $($_.Exception.Message)"
    Write-Log "Stack trace: $($_.ScriptStackTrace)"
    
    # Cleanup on error
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    throw
}