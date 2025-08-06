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

# Install the ServerMediaFoundation feature
Write-Host "Installing ServerMediaFoundation feature..."
try {
    $result = dism /online /enable-feature /featurename:ServerMediaFoundation /Source:O:\ /LimitAccess
    Write-Host "DISM output: $result"
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne 3010) {
        throw "DISM command failed with exit code $LASTEXITCODE"
    }
    Write-Host "ServerMediaFoundation feature installed successfully"
}
catch {
    Write-Error "Failed to install ServerMediaFoundation: $($_.Exception.Message)"
    # Clean up the drive mapping before exiting
    try {
        Remove-PSDrive -Name "O" -Force -ErrorAction SilentlyContinue
    }
    catch { }
    exit 1
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
