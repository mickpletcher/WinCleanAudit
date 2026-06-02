# Usage Examples

## DryRun

```powershell
.\src\WinCleanAudit.ps1 -DryRun
```

DryRun writes Markdown and HTML reports.
The HTML report opens in your default browser.

## DryRun Without Browser Launch

```powershell
.\src\WinCleanAudit.ps1 -DryRun -NoBrowserLaunch
```

## Execute With Confirmation

```powershell
.\src\WinCleanAudit.ps1 -Execute
```

## Execute With NoPrompt

```powershell
.\src\WinCleanAudit.ps1 -Execute -NoPrompt
```

Execute mode records attempted deletes, skipped cleanup items, and service
actions in `ExecutionLog`.

## Report Path Override

```powershell
.\src\WinCleanAudit.ps1 -DryRun -ReportPath .\reports
```

## Optional JSON And CSV Reports

```powershell
.\src\WinCleanAudit.ps1 -DryRun -JsonReport -CsvReport
```

## Enterprise Audit Policy Profile

Set this in `tasks/windows-cleanup.yaml`:

```yaml
execution:
  policy_profile: enterprise_audit
```

## Scheduled DryRun

```powershell
.\src\Install-WinCleanAuditScheduledTask.ps1 -Frequency Weekly -JsonReport -CsvReport
```

The scheduled task runs DryRun with `-NoBrowserLaunch`.

## Enterprise Detection

Use these for managed deployment detection:

```text
deployment/intune/detect.ps1
deployment/configmgr/detection-method.ps1
```

Both detection scripts check script presence, config presence, scheduled task
registration, and recent JSON report generation.

## ConfigMgr Compliance Baseline

Examples are here:

```text
deployment/configmgr/compliance-baseline/
```

## Packaging Templates

Managed packaging templates are here:

```text
deployment/packaging/
```

## Module Notes

- Temp cleanup audits approved temp folders in DryRun.
- Windows Update cache cleanup only removes child items in the download folder
  and validates service restart state after cleanup.
- Recycle bin cleanup only runs in Execute mode.
- Old log cleanup targets safe system locations and age threshold.
- Browser cache cleanup targets cache files only and skips profile data.
- Startup inventory is audit only.
- Large file report is audit only and defaults to 500 MB threshold.
- Duplicate downloads report is audit only.
- Installed apps inventory is audit only.
- Disk health report is read only.
