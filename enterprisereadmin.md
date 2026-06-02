# WinCleanAudit Enterprise Admin Guide

This guide is for enterprise endpoint admins deploying WinCleanAudit across
managed Windows devices.

Use it for audit first.

Do not start with cleanup.

## Recommended Enterprise Use

Use WinCleanAudit to:

- Audit disk usage and cleanup candidates.
- Find old logs, temp files, browser cache usage, duplicate downloads, large
  files, startup items, installed apps, recycle bin usage, and disk health
  signals.
- Generate local Markdown and HTML reports.
- Generate JSON and CSV reports for collection or downstream reporting.
- Run recurring DryRun scans through a scheduled task.

Do not use WinCleanAudit to:

- Delete user data.
- Replace Intune, ConfigMgr, EDR, backup, or patch management.
- Run broad cleanup without reviewing DryRun output.
- Clean browser profile data such as passwords, cookies, history, bookmarks,
  profiles, or extensions.

## Safety Defaults

Default mode is `DryRun`.

Cleanup requires explicit `-Execute`.

`-NoPrompt` is blocked unless `-Execute` is also passed.

DryRun writes reports and does not delete files.

Protected locations are excluded:

- Desktop
- Documents
- Pictures
- Videos
- Music
- OneDrive
- Dropbox
- Google Drive
- Git repositories
- Source code folders

Redirected known folders and enterprise Folder Redirection paths are also
protected when they are present in the current user shell folder registry keys.

Execute mode records attempted deletes, skipped cleanup items, and service
actions in `ExecutionLog`.

Windows Update cache cleanup validates that services running before cleanup are
running again after restart.

## Recommended Policy Profile

For fleet audit, use the `enterprise_audit` policy profile in
`tasks/windows-cleanup.yaml`:

```yaml
execution:
  policy_profile: enterprise_audit
```

This profile enables JSON and CSV exports and Windows Event Log output.

Use the default profile for local testing before enterprise deployment.

## Recommended First Run

Run this from an elevated or standard PowerShell session:

```powershell
.\src\WinCleanAudit.ps1 -DryRun -NoBrowserLaunch -JsonReport -CsvReport
```

Review:

- Markdown report
- HTML report
- JSON report
- CSV report
- Log file
- Warnings
- Errors
- Recommendations
- `ExecutionLog` entries when testing Execute mode

Reports are written under:

```text
reports/
```

## Intune Deployment

Use the install script:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\deployment\intune\install.ps1 -RegisterScheduledTask
```

Use the detection script:

```text
deployment/intune/detect.ps1
```

The scheduled task runs DryRun with:

- `-NoBrowserLaunch`
- JSON export
- CSV export
- Enterprise report path

The detection script verifies script presence, config presence, scheduled task
registration, and recent JSON report generation.

Package the repository content with the Intune Win32 Content Prep Tool.

Target a pilot group first.

Review reports before broad deployment.

## ConfigMgr Deployment

Use the install script:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\deployment\configmgr\install.ps1 -RegisterScheduledTask
```

Use the detection method:

```text
deployment/configmgr/detection-method.ps1
```

Compliance baseline examples are here:

```text
deployment/configmgr/compliance-baseline/
```

Deploy to a pilot collection first.

Start with scheduled DryRun only.

Do not deploy Execute mode as a baseline until you have reviewed pilot results.

## Scheduled Task Behavior

The scheduled task installer is:

```powershell
.\src\Install-WinCleanAuditScheduledTask.ps1 -Frequency Weekly -JsonReport -CsvReport
```

Scheduled DryRun tasks include `-NoBrowserLaunch`.

Use `-RunAsSystem` for managed recurring scans:

```powershell
.\src\Install-WinCleanAuditScheduledTask.ps1 -Frequency Weekly -JsonReport -CsvReport -RunAsSystem
```

System context can see different profile paths than a user context.

Validate report output from the actual deployment context.

## Report Collection

Reports are local by default.

For enterprise reporting, collect:

- `cleanup-report-*.json`
- `cleanup-report-*.csv`
- `wincleanaudit-*.log`

Use Intune proactive remediation output, ConfigMgr file collection, scheduled
copy jobs, or your existing reporting pipeline.

Generated reports and logs are ignored by git.

Do not commit endpoint reports.

## Event Log Mapping

When Event Log output is enabled, WinCleanAudit maps failure categories to
event IDs:

| Category | Event ID |
| --- | ---: |
| Info | 1000 |
| Success | 1001 |
| Warning | 2000 |
| AccessDenied | 2101 |
| LockedFile | 2102 |
| MissingPath | 2103 |
| ServiceControlError | 2104 |
| GeneralError | 3000 |

## Managed Packaging

Packaging templates are here:

```text
deployment/packaging/
```

The folder includes winget style manifests and a WiX MSI template.

Treat them as release packaging starters.

Update release URLs, hashes, publisher metadata, upgrade codes, and signing
before production use.

## Execute Mode Guidance

Use Execute mode only after DryRun review.

Manual confirmed cleanup:

```powershell
.\src\WinCleanAudit.ps1 -Execute
```

Unattended cleanup:

```powershell
.\src\WinCleanAudit.ps1 -Execute -NoPrompt
```

Do not use unattended cleanup until:

- Pilot DryRun reports are reviewed.
- Protected path behavior is verified.
- Browser profile exclusions are verified.
- Windows Update service restart behavior is verified.
- Reports and logs are being collected.
- Rollback and support procedures are documented.

## Admin Rights

Most audit modules can run without elevation.

Windows Update cache cleanup in Execute mode requires administrator rights.

Some inventory and disk health results may vary by permission level.

Run the same context in pilot that you plan to use in production.

## Operational Checks

Before deployment:

```powershell
Invoke-Pester -Path .\tests\Pester -CI
```

Expected current result:

```text
63 tests passed
0 tests failed
```

Run a smoke test:

```powershell
.\src\WinCleanAudit.ps1 -DryRun -NoBrowserLaunch -JsonReport -CsvReport
```

Confirm:

- Reports are created.
- No browser opens.
- Generated files stay out of git.
- Warnings and errors are understandable.
- Pilot endpoints do not show unexpected protected path findings.

## Recommended Rollout

1. Validate locally.
2. Deploy DryRun to a small pilot group.
3. Collect JSON and CSV reports.
4. Review warnings, errors, and recommendations.
5. Tune policy and module selection.
6. Expand DryRun to a larger group.
7. Consider Execute only for narrow, approved cleanup targets.

For most enterprise use, recurring DryRun reporting is the safer default.
