REM Connect to the WinSxS share on the container host
for /f "tokens=3 delims=: " %%g in ('netsh interface ip show address ^| findstr /c:"Default Gateway"') do set GATEWAY=%%g
net use o: \\%GATEWAY%\WinSxS /user:ShareUser %SHARE_PW%
if errorlevel 1 goto :eof
 
REM Install the ServerMediaFoundation feature
dism /online /enable-feature /featurename:ServerMediaFoundation /Source:O:\ /LimitAccess