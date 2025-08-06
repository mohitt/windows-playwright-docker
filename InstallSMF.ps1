# Media Foundation is CRITICAL for Chromium/Playwright to work in Windows containers
Write-Host "=== Media Foundation Installation (CRITICAL for Chromium) ==="

# Connect to the WinSxS share on the container host
# Get the default gateway IP address
$Gateway = (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -ne $null}).IPv4DefaultGateway.NextHop

Write-Host "Connecting to share at gateway: $Gateway"

$ShareConnected = $false
# Map the network drive using PowerShell
try {
    New-PSDrive -Name "O" -PSProvider FileSystem -Root "\\$Gateway\WinSxS" -Credential (New-Object System.Management.Automation.PSCredential("ShareUser", (ConvertTo-SecureString $env:SHARE_PW -AsPlainText -Force))) -ErrorAction Stop
    Write-Host "Successfully connected to WinSxS share"
    $ShareConnected = $true
}
catch {
    Write-Warning "Failed to connect to WinSxS share: $($_.Exception.Message)"
    Write-Host "Will attempt installation without external source"
}

# Check if ServerMediaFoundation is already installed
Write-Host "Checking current feature state..."
try {
    $featureInfo = Get-WindowsOptionalFeature -Online -FeatureName ServerMediaFoundation
    Write-Host "Current feature state: $($featureInfo.State)"
    
    if ($featureInfo.State -eq "Enabled") {
        Write-Host "ServerMediaFoundation is already enabled - Chromium should work!"
        return
    }
}
catch {
    Write-Warning "Could not check feature state: $($_.Exception.Message)"
}

# Install the ServerMediaFoundation feature using multiple strategies
Write-Host "Installing ServerMediaFoundation feature (REQUIRED for Chromium)..."

$InstallSuccess = $false

# Strategy 1: Try without external source (Windows Update/built-in)
Write-Host "Strategy 1: Attempting installation using Windows Update/built-in sources..."
try {
    $result = Enable-WindowsOptionalFeature -Online -FeatureName ServerMediaFoundation -All -NoRestart
    
    if ($result.RestartNeeded) {
        Write-Host "✅ Strategy 1 SUCCESS: Feature installed (restart required)"
        $InstallSuccess = $true
    } else {
        Write-Host "✅ Strategy 1 SUCCESS: Feature installed successfully"
        $InstallSuccess = $true
    }
}
catch {
    Write-Warning "❌ Strategy 1 FAILED: $($_.Exception.Message)"
}

# Strategy 2: Try with WinSxS source if available and Strategy 1 failed
if (-not $InstallSuccess -and $ShareConnected -and (Test-Path "O:\")) {
    Write-Host "Strategy 2: Attempting installation with WinSxS source..."
    try {
        $result = Enable-WindowsOptionalFeature -Online -FeatureName ServerMediaFoundation -Source "O:\" -LimitAccess -All -NoRestart
        
        if ($result.RestartNeeded) {
            Write-Host "✅ Strategy 2 SUCCESS: Feature installed with external source (restart required)"
            $InstallSuccess = $true
        } else {
            Write-Host "✅ Strategy 2 SUCCESS: Feature installed with external source"
            $InstallSuccess = $true
        }
    }
    catch {
        Write-Warning "❌ Strategy 2 FAILED: $($_.Exception.Message)"
    }
}

# Strategy 3: Try DISM as last resort
if (-not $InstallSuccess) {
    Write-Host "Strategy 3: Attempting installation with DISM as last resort..."
    try {
        if ($ShareConnected -and (Test-Path "O:\")) {
            $dismResult = dism /online /enable-feature /featurename:ServerMediaFoundation /Source:O:\ /LimitAccess /All /NoRestart
        } else {
            $dismResult = dism /online /enable-feature /featurename:ServerMediaFoundation /All /NoRestart
        }
        
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq 3010) {
            Write-Host "✅ Strategy 3 SUCCESS: DISM installation completed"
            $InstallSuccess = $true
        } else {
            Write-Warning "❌ Strategy 3 FAILED: DISM exit code $LASTEXITCODE"
        }
    }
    catch {
        Write-Warning "❌ Strategy 3 FAILED: $($_.Exception.Message)"
    }
}

# Strategy 4: Download Media Foundation source files from remote location
if (-not $InstallSuccess) {
    Write-Host "Strategy 4: Downloading Media Foundation source files from remote location..."
    try {
        # Create temporary directory for downloaded sources
        $TempSourceDir = "C:\temp\mf_source"
        New-Item -ItemType Directory -Path $TempSourceDir -Force | Out-Null
        
        # Try multiple remote source URLs (in order of preference)
        $RemoteSourceUrls = @(
            "https://github.com/microsoft/Windows-universal-samples/releases/download/v6.4.2/MediaFoundation_CAB.zip",
            "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/windowsmedia-format-11-sdk.exe",
            "https://aka.ms/mediaFoundationSources"  # Microsoft alias (if available)
        )
        
        $DownloadSuccess = $false
        foreach ($url in $RemoteSourceUrls) {
            try {
                Write-Host "   Trying to download from: $url"
                $fileName = Split-Path $url -Leaf
                $downloadPath = Join-Path $TempSourceDir $fileName
                
                # Download with progress indication
                Invoke-WebRequest -Uri $url -OutFile $downloadPath -UseBasicParsing -TimeoutSec 300
                
                if (Test-Path $downloadPath) {
                    Write-Host "   ✅ Downloaded successfully: $fileName"
                    
                    # If it's a zip file, extract it
                    if ($fileName.EndsWith('.zip')) {
                        $extractPath = Join-Path $TempSourceDir "extracted"
                        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
                        $sourcePath = $extractPath
                    } else {
                        $sourcePath = $TempSourceDir
                    }
                    
                    # Try to install using the downloaded source
                    Write-Host "   Attempting installation with downloaded source..."
                    $result = Enable-WindowsOptionalFeature -Online -FeatureName ServerMediaFoundation -Source $sourcePath -LimitAccess -All -NoRestart
                    
                    if ($result.RestartNeeded) {
                        Write-Host "✅ Strategy 4 SUCCESS: Feature installed with downloaded source (restart required)"
                        $InstallSuccess = $true
                        $DownloadSuccess = $true
                        break
                    } else {
                        Write-Host "✅ Strategy 4 SUCCESS: Feature installed with downloaded source"
                        $InstallSuccess = $true
                        $DownloadSuccess = $true
                        break
                    }
                }
            }
            catch {
                Write-Warning "   ❌ Failed to download/install from $url : $($_.Exception.Message)"
                continue
            }
        }
        
        if (-not $DownloadSuccess) {
            Write-Warning "❌ Strategy 4 FAILED: Could not download Media Foundation sources from any remote location"
        }
        
        # Clean up temporary files
        try {
            Remove-Item -Path $TempSourceDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Could not clean up temporary download directory: $($_.Exception.Message)"
        }
    }
    catch {
        Write-Warning "❌ Strategy 4 FAILED: $($_.Exception.Message)"
    }
}

# Final verification
if ($InstallSuccess) {
    Write-Host "🎉 Media Foundation installation completed successfully!"
    Write-Host "   Chromium/Playwright should now work properly"
} else {
    Write-Error "💥 CRITICAL: Failed to install Media Foundation!"
    Write-Host "   Without Media Foundation, Chromium will NOT start properly"
    Write-Host "   Consider using Windows Server (full) instead of Server Core"
    Write-Host "   Or install Media Foundation manually in the base image"
    exit 1
}
finally {
    # Clean up the drive mapping if it was created
    if ($ShareConnected) {
        try {
            Remove-PSDrive -Name "O" -Force -ErrorAction SilentlyContinue
            Write-Host "Cleaned up drive mapping"
        }
        catch {
            Write-Warning "Could not remove drive mapping: $($_.Exception.Message)"
        }
    }
}
