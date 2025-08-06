### Windows Server 2022 Core with Playwright

```
This image can only be built on Windows server 2022
```

## GitHub Actions Setup

This repository includes a GitHub Actions workflow that automatically builds and publishes the Docker image to GitHub Container Registry (ghcr.io).

### Required GitHub Secret

Before the workflow can run successfully, you need to set up the following secret in your GitHub repository:

1. Go to your repository settings
2. Navigate to "Secrets and variables" → "Actions"
3. Click "New repository secret"
4. Add the following secret:

**Secret Name:** `SHARE_USER_PASSWORD`
**Secret Value:** A secure password for the temporary ShareUser account used during the build process

### Workflow Triggers

The workflow runs on:
- Push to `master` or `main` branch
- Pull requests to `master` or `main` branch
- Manual trigger via workflow dispatch

### Local Development

To build locally, you can still run the build script interactively:

```powershell
.\build.ps1
```

The script will prompt for the ShareUser password if the `SHARE_USER_PASSWORD` environment variable is not set.
