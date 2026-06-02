# Deployment Templates

This folder contains starter deployment templates for enterprise endpoint
fleets.

## Intune

Use `deployment/intune/install.ps1` as the Win32 app install command.

Use `deployment/intune/detect.ps1` as the detection script.

Example install command:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\deployment\intune\install.ps1 -RegisterScheduledTask
```

## ConfigMgr

Use `deployment/configmgr/install.ps1` as the application install command.

Use `deployment/configmgr/detection-method.ps1` as the detection method.

Example install command:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\deployment\configmgr\install.ps1 -RegisterScheduledTask
```

## Policy Profiles

Select the policy profile in `tasks/windows-cleanup.yaml`:

```yaml
execution:
  policy_profile: enterprise_audit
```
