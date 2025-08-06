# Get password from environment variable (GitHub secret) or prompt user if not set
if ($env:SHARE_USER_PASSWORD) {
    $UserPassword = $env:SHARE_USER_PASSWORD
    Write-Host "Using password from environment variable"
} else {
    $UserPassword = Read-Host -Prompt "Enter the password for the share user"
}

# Create user using PowerShell
$SecurePassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
New-LocalUser -Name "ShareUser" -Password $SecurePassword -PasswordNeverExpires
# Create the share using PowerShell
New-SmbShare -Name "WinSxS" -Path "$env:windir\WinSxS" -ReadAccess "ShareUser"
#put the UserPassword in an environment variable
#[Environment]::SetEnvironmentVariable("ShareUserPassword", $UserPassword, [EnvironmentVariableTarget]::Machine)
docker build -t windows-playwright:latest --build-arg SHARE_PW=$UserPassword .

# Clean up using PowerShell
Remove-SmbShare -Name "WinSxS" -Force
Remove-LocalUser -Name "ShareUser"

