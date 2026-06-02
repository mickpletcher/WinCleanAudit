# Managed Packaging

This folder contains starter packaging templates for managed deployment.

They are templates.

They do not build signed release artifacts by themselves.

## Winget Style Package

The `winget/` folder contains example manifests for a future WinCleanAudit
release package.

Before publishing, update:

- Version.
- Installer URL.
- SHA256 hash.
- Publisher metadata.
- License URL.

## MSI Style Package

The `msi/wix/Product.wxs` file is a starter WiX template.

Before building, update:

- Upgrade code.
- Manufacturer.
- Source file paths.
- Version.
- Install scope.
- Signing workflow.

## Recommended Enterprise Flow

1. Build or package from a clean release branch.
2. Sign scripts or installer artifacts.
3. Generate checksums.
4. Pilot deployment through Intune or ConfigMgr.
5. Verify scheduled task registration and recent report generation.
