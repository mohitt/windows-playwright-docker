# Get password from environment variable (GitHub secret) or prompt user if not set
if ($env:SHARE_USER_PASSWORD) {
    $UserPassword = $env:SHARE_USER_PASSWORD
    Write-Host "Using password from environment variable"
} else {
    $UserPassword = Read-Host -Prompt "Enter the password for the share user"
}
net user ShareUser $UserPassword /ADD
net share WinSxS=%windir%\WinSxS /GRANT:ShareUser,READ
#put the UserPassword in an environment variable
#[Environment]::SetEnvironmentVariable("ShareUserPassword", $UserPassword, [EnvironmentVariableTarget]::Machine)
docker build -t windows-playwright:latest --build-arg SHARE_PW=$UserPassword .

net share WinSxS /DELETE
net user ShareUser /DELETE

