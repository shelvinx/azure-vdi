# scripts/fslogix-config.ps1
# FSLogix Configuration Script for AVD Session Hosts

param(
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountName,
    
    [Parameter(Mandatory = $true)]
    [string]$StorageAccountKey,
    
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

try {
    Write-Log "Starting FSLogix configuration..."
    
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
    
    # Concurrent user sessions
    Set-RegistryValue -Path $fslogixRegPath -Name "PreventLoginWithFailure" -Value 1
    Set-RegistryValue -Path $fslogixRegPath -Name "PreventLoginWithTempProfile" -Value 1
    
    # Performance settings
    Set-RegistryValue -Path $fslogixRegPath -Name "ProfileType" -Value 0  # Normal profiles
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
    
    # Configure storage account authentication
    Write-Log "Configuring storage account authentication..."
    
    # Add storage account credentials using cmdkey
    $cmdkeyArgs = @(
        "/add:$StorageAccountName.file.core.windows.net",
        "/user:Azure\$StorageAccountName",
        "/pass:$StorageAccountKey"
    )
    
    $cmdkeyProcess = Start-Process -FilePath "cmdkey.exe" -ArgumentList $cmdkeyArgs -Wait -PassThru -NoNewWindow
    if ($cmdkeyProcess.ExitCode -eq 0) {
        Write-Log "Storage account credentials added successfully"
    } else {
        Write-Log "WARNING: Failed to add storage credentials with cmdkey"
    }

    
    # Test connectivity to file share
    Write-Log "Testing connectivity to file shares..."
    try {
        $testPath = "\\$StorageAccountName.file.core.windows.net\$ProfileShare"
        if (Test-Path $testPath) {
            Write-Log "Successfully connected to profile share: $testPath"
        } else {
            Write-Log "WARNING: Cannot access profile share: $testPath"
        }
    }
    catch {
        Write-Log "WARNING: Error testing profile share connectivity - $($_.Exception.Message)"
    }
    
    # Cleanup temp files
    Write-Log "Cleaning up temporary files..."
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "FSLogix configuration completed successfully!"
    
    # Create verification file
    $verificationFile = "C:\FSLogix-Configured.txt"
    $verificationContent = @"
FSLogix Configuration Completed
===============================
Date: $(Get-Date)
Storage Account: $StorageAccountName
Profile Share: $ProfileShare
Office Share: $OfficeShare
Status: SUCCESS
"@
    $verificationContent | Out-File -FilePath $verificationFile -Force
    Write-Log "Created verification file: $verificationFile"
    
} catch {
    Write-Log "ERROR: FSLogix configuration failed - $($_.Exception.Message)"
    Write-Log "Stack trace: $($_.ScriptStackTrace)"
    
    # Cleanup on error
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    throw
}