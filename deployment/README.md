# Deployment Templates

This folder contains starter deployment templates for enterprise endpoint
fleets.

## Intune

Use `deployment/intune/install.ps1` as the Win32 app install command.

Use `deployment/intune/detect.ps1` as the detection script.

The detection script verifies:

- WinCleanAudit script presence.
- Config presence.
- Scheduled task registration.
- Recent JSON report generation.

Example install command:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\deployment\intune\install.ps1 -RegisterScheduledTask
```

When scheduled task registration is enabled, the task runs DryRun with
`-NoBrowserLaunch`, JSON export, CSV export, and the enterprise report path.

## ConfigMgr

Use `deployment/configmgr/install.ps1` as the application install command.

Use `deployment/configmgr/detection-method.ps1` as the detection method.

The detection method verifies:

- WinCleanAudit script presence.
- Config presence.
- Scheduled task registration.
- Recent JSON report generation.

Example install command:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\deployment\configmgr\install.ps1 -RegisterScheduledTask
```

When scheduled task registration is enabled, the task runs DryRun with
`-NoBrowserLaunch`, JSON export, CSV export, and the enterprise report path.

Compliance baseline examples are under:

```text
deployment/configmgr/compliance-baseline/
```

## Packaging

Managed packaging templates are under:

```text
deployment/packaging/
```

This includes:

- A winget style manifest template.
- A WiX MSI template.

These are starter templates and need release URLs, hashes, signing, and
publisher metadata before production use.

## Policy Profiles

Select the policy profile in `tasks/windows-cleanup.yaml`:

```yaml
execution:
  policy_profile: enterprise_audit
```
