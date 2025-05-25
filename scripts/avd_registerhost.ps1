# AVD Session Host Registration Script

param(
    [Parameter(Mandatory = $true)]
    [string]$RegistrationToken,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\AVD-Registration.log"
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $Message"
    Write-Host $logMessage
    $logMessage | Out-File -FilePath $LogPath -Append
}

function Test-RegistryPath {
    param([string]$Path)
    try {
        return Test-Path "Registry::$Path"
    }
    catch {
        return $false
    }
}

try {
    Write-Log "Starting AVD Session Host Registration..."
    
    # Check if already registered
    if (Test-RegistryPath "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent") {
        Write-Log "Session host already registered. Checking if re-registration is needed..."
        
        # You might want to check token validity or force re-registration here
        # For now, we'll skip if already registered
        Write-Log "Registration already completed. Exiting."
        exit 0
    }
    
    # Create temp directory
    $tempDir = "C:\temp\avd"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    Write-Log "Created temp directory: $tempDir"
    
    # Download AVD Agent
    Write-Log "Downloading Remote Desktop Agent..."
    $agentUrl = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv"
    $agentPath = "$tempDir\Microsoft.RDInfra.RDAgent.Installer.msi"
    Invoke-WebRequest -Uri $agentUrl -OutFile $agentPath
    Write-Log "Downloaded agent to: $agentPath"
    
    # Install AVD Agent
    Write-Log "Installing Remote Desktop Agent..."
    $agentArgs = @(
        "/i", $agentPath,
        "/quiet",
        "/norestart",
        "REGISTRATIONTOKEN=$RegistrationToken"
    )
    $agentProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList $agentArgs -Wait -PassThru
    
    if ($agentProcess.ExitCode -ne 0) {
        throw "Agent installation failed with exit code: $($agentProcess.ExitCode)"
    }
    Write-Log "Remote Desktop Agent installed successfully"
    
    # Download Boot Loader
    Write-Log "Downloading Remote Desktop Agent Boot Loader..."
    $bootLoaderUrl = "https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH"
    $bootLoaderPath = "$tempDir\Microsoft.RDInfra.RDAgentBootLoader.Installer.msi"
    Invoke-WebRequest -Uri $bootLoaderUrl -OutFile $bootLoaderPath
    Write-Log "Downloaded boot loader to: $bootLoaderPath"
    
    # Install Boot Loader
    Write-Log "Installing Remote Desktop Agent Boot Loader..."
    $bootLoaderArgs = @(
        "/i", $bootLoaderPath,
        "/quiet",
        "/norestart"
    )
    $bootLoaderProcess = Start-Process -FilePath "msiexec.exe" -ArgumentList $bootLoaderArgs -Wait -PassThru
    
    if ($bootLoaderProcess.ExitCode -ne 0) {
        throw "Boot Loader installation failed with exit code: $($bootLoaderProcess.ExitCode)"
    }
    Write-Log "Remote Desktop Agent Boot Loader installed successfully"
    
    # Wait a moment for services to initialize
    Write-Log "Waiting for services to initialize..."
    Start-Sleep -Seconds 30
    
    # Verify registration
    if (Test-RegistryPath "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent") {
        Write-Log "Session host registration completed successfully!"
        
        # Check if services are running
        $rdAgentService = Get-Service -Name "RDAgentBootLoader" -ErrorAction SilentlyContinue
        if ($rdAgentService -and $rdAgentService.Status -eq "Running") {
            Write-Log "RDAgentBootLoader service is running"
        } else {
            Write-Log "RDAgentBootLoader service is not running as expected"
        }
    } else {
        throw "Registration verification failed - registry key not found"
    }
    
    # Cleanup
    Write-Log "Cleaning up temporary files..."
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "AVD Session Host Registration completed successfully!"
    
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Log "Stack trace: $($_.ScriptStackTrace)"
    
    # Cleanup on error
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    
    throw
}