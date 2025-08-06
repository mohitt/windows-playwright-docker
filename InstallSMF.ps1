# Connect to the WinSxS share on the container host
# Get the default gateway IP address
$Gateway = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null}).IPv4DefaultGateway.NextHop

Write-Host "Connecting to share at gateway: $Gateway"

# Map the network drive using PowerShell
try {
    New-PSDrive -Name "O" -PSProvider FileSystem -Root "\\$Gateway\WinSxS" -Credential (New-Object System.Management.Automation.PSCredential("ShareUser", (ConvertTo-SecureString $env:SHARE_PW -AsPlainText -Force))) -ErrorAction Stop
    Write-Host "Successfully connected to WinSxS share"
}
catch {
    Write-Error "Failed to connect to WinSxS share: $($_.Exception.Message)"
    exit 1
}

# Check if ServerMediaFoundation is already installed
Write-Host "Checking current feature state..."
try {
    $featureInfo = Get-WindowsOptionalFeature -Online -FeatureName ServerMediaFoundation
    Write-Host "Current feature state: $($featureInfo.State)"
    
    if ($featureInfo.State -eq "Enabled") {
        Write-Host "ServerMediaFoundation is already enabled"
        return
    }
}
catch {
    Write-Warning "Could not check feature state: $($_.Exception.Message)"
}

# Install the ServerMediaFoundation feature using PowerShell
Write-Host "Installing ServerMediaFoundation feature using PowerShell..."
try {
    # Try with external source first
    Write-Host "Attempting installation with WinSxS source..."
    $result = Enable-WindowsOptionalFeature -Online -FeatureName ServerMediaFoundation -Source "O:\" -LimitAccess -All
    
    if ($result.RestartNeeded) {
        Write-Host "Feature installed successfully (restart required)"
    } else {
        Write-Host "Feature installed successfully"
    }
}
catch {
    Write-Warning "Installation with source failed: $($_.Exception.Message)"
    Write-Host "Attempting installation without external source..."
    
    try {
        # Fallback: Try without source
        $result = Enable-WindowsOptionalFeature -Online -FeatureName ServerMediaFoundation -All
        
        if ($result.RestartNeeded) {
            Write-Host "Feature installed successfully without external source (restart required)"
        } else {
            Write-Host "Feature installed successfully without external source"
        }
    }
    catch {
        Write-Error "Failed to install ServerMediaFoundation with PowerShell: $($_.Exception.Message)"
        # Clean up the drive mapping before exiting
        try {
            Remove-PSDrive -Name "O" -Force -ErrorAction SilentlyContinue
        }
        catch { }
        exit 1
    }
}
finally {
    # Clean up the drive mapping
    try {
        Remove-PSDrive -Name "O" -Force -ErrorAction SilentlyContinue
        Write-Host "Cleaned up drive mapping"
    }
    catch {
        Write-Warning "Could not remove drive mapping: $($_.Exception.Message)"
    }
}
