# Base image with Windows Server Core (smaller, no Media Foundation)
FROM mcr.microsoft.com/windows/servercore:ltsc2022

SHELL ["powershell", "-Command"]

# Install Node.js
RUN Invoke-WebRequest https://nodejs.org/dist/v22.18.0/node-v22.18.0-x64.msi -OutFile node.msi ; \
    Start-Process msiexec.exe -ArgumentList '/qn /i node.msi' -Wait ; \
    Remove-Item node.msi

# Install Visual C++ Redistributables (required for Chromium)
RUN Invoke-WebRequest https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile vc_redist.x64.exe ; \
    Start-Process .\vc_redist.x64.exe -ArgumentList '/quiet' -Wait ; \
    Remove-Item .\vc_redist.x64.exe

# Install Git (for dependencies if needed)
RUN Invoke-WebRequest https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe -OutFile git.exe ; \
    Start-Process .\git.exe -ArgumentList '/VERYSILENT' -Wait ; \
    Remove-Item .\git.exe


# Set environment variables for Playwright
ENV PLAYWRIGHT_BROWSERS_PATH=C:/ms-playwright
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=false

RUN $env:PLAYWRIGHT_BROWSERS_PATH = 'C:/ms-playwright' ; \
    npm install -g playwright; \
    npx playwright install chromium --with-deps;



