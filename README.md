### Windows Server 2022 with Playwright

```
This image uses Windows Server 2022 (full) which includes Media Foundation support for Chromium/Playwright
```

## GitHub Actions Setup

This repository includes a GitHub Actions workflow that automatically builds and publishes the Docker image to GitHub Container Registry (ghcr.io) using the standard Docker build process.

### Workflow Triggers

The workflow runs on:
- Push to `master` or `main` branch
- Pull requests to `master` or `main` branch
- Manual trigger via workflow dispatch

### Local Development

To build locally, you can use standard Docker commands:

```powershell
docker build -t windows-playwright:latest .
```

The build uses Windows Server 2022 (full) which includes Media Foundation components required for Chromium to function properly.
