# WinCleanAudit

[![PowerShell Tests][powershell-tests-badge]][powershell-tests-workflow]
[![Markdown Lint][markdown-lint-badge]][markdown-lint-workflow]

Version: v1.0.0

WinCleanAudit is a Windows cleanup and audit tool built with PowerShell.

It is designed to be safe first.

By default, it only scans your computer and writes a report.
It does not delete anything unless you explicitly run it in execute mode.

## Who This Is For

Use this tool if you want to:

* See where disk space may be wasted.
* Review old logs, temp files, browser cache, and Recycle Bin usage.
* Inventory startup items and installed apps.
* Check disk usage and basic disk health.
* Generate Markdown, HTML, JSON, and CSV reports you can review later.

You do not need to be a PowerShell expert to run a basic scan.

## The Most Important Safety Rule

Start with this command:

```powershell
.\src\WinCleanAudit.ps1 -DryRun
```

`-DryRun` means audit only.

It scans and reports. It does not clean or delete files.

Do not use `-Execute` until you have reviewed the report and understand what
will happen.

## Quick Start

1. Open PowerShell.
2. Go to the folder where this repo is saved.
3. Run a safe scan:

```powershell
.\src\WinCleanAudit.ps1 -DryRun
```

1. Review the HTML report that opens in your browser.
2. Review warnings, errors, and recommendations.

Reports are saved here:

```text
reports/
```

Report files use this format:

```text
cleanup-report-YYYYMMDD-HHMMSS.md
cleanup-report-YYYYMMDD-HHMMSS.html
cleanup-report-YYYYMMDD-HHMMSS.json
cleanup-report-YYYYMMDD-HHMMSS.csv
```

## PowerShell Help

The main scripts include comment based help:

```powershell
Get-Help .\src\WinCleanAudit.ps1 -Detailed
Get-Help .\src\Install-WinCleanAuditScheduledTask.ps1 -Detailed
Get-Help .\deployment\intune\detect.ps1 -Detailed
Get-Help .\deployment\configmgr\detection-method.ps1 -Detailed
```

Use `-Examples` for copyable command examples.

## Run Modes

### DryRun

Safe audit mode.

```powershell
.\src\WinCleanAudit.ps1 -DryRun
```

Use this first. It scans, writes reports, and opens the HTML report in your
browser. It does not delete anything.

For automation, suppress the browser launch:

```powershell
.\src\WinCleanAudit.ps1 -DryRun -NoBrowserLaunch
```

### Execute

Cleanup mode.

```powershell
.\src\WinCleanAudit.ps1 -Execute
```

This can delete approved cleanup targets after confirmation.

Use this only after reading the DryRun report.

### Optional JSON And CSV Reports

Use these switches when you want machine-readable report exports:

```powershell
.\src\WinCleanAudit.ps1 -DryRun -JsonReport -CsvReport
```

JSON contains the full report object.
CSV contains one summary row per module.

### Execute With NoPrompt

Automation mode.

```powershell
.\src\WinCleanAudit.ps1 -Execute -NoPrompt
```

This skips confirmation prompts.
Use it only in trusted automation after testing.

The tool blocks this unsafe command:

```powershell
.\src\WinCleanAudit.ps1 -NoPrompt
```

`-NoPrompt` is allowed only with `-Execute`.

## What The Tool Checks

### Cleanup Modules

These modules can clean only when you use `-Execute`.

| Module | What It Does |
| --- | --- |
| TempCleanup | Reviews approved Windows temp folders. |
| WindowsUpdateCache | Reviews Windows Update download cache. Cleanup may require admin rights. |
| RecycleBin | Reviews Recycle Bin contents. |
| OldLogCleanup | Finds old log-like files in approved system log locations. |
| BrowserCache | Reviews browser cache for Chrome, Edge, Firefox, Brave, and Opera. |

### Audit Modules

These modules report only. They do not delete or disable anything.

| Module | What It Does |
| --- | --- |
| StartupInventory | Lists startup folder items, registry startup items, and logon scheduled tasks. |
| LargeFileReport | Finds large files for manual review. |
| DuplicateDownloads | Finds likely duplicate files in Downloads. |
| InstalledApps | Lists installed applications from registry uninstall entries. |
| DiskHealth | Reports volume usage and disk health where available. |

## What The Tool Avoids

WinCleanAudit is designed to avoid user data and source code.

It should not delete from:

* Desktop
* Documents
* Pictures
* Videos
* Music
* OneDrive
* Dropbox
* Google Drive
* Redirected known folders
* Git repositories
* Source-code folders

If one module fails, the rest of the tool should continue running.
The error should appear in the report.

## Reading The Report

The report includes:

* Computer name
* User name
* PowerShell version
* Run mode
* Module results
* Actions taken
* Warnings
* Errors
* Recommendations
* ExecutionLog entries for execute mode delete, skip, and service actions

Optional JSON and CSV reports use the same timestamp as the Markdown report.

For a normal first run, look for:

* `Mode`: should be `DryRun`
* `Errors`: anything that failed
* `Warnings`: access denied, locked files, or skipped paths
* `Recommendations`: items to review manually

## Administrator Notes

Some checks work better when PowerShell is run as administrator.

Windows Update cache cleanup requires administrator rights in execute mode.
It validates that services running before cleanup are running again after
restart.

For normal review, start without admin rights and use `-DryRun`.

## Testing

Run tests with:

```powershell
Invoke-Pester -Path .\tests\Pester
```

The test suite checks imports, DryRun behavior, output shape, safety guards,
failure classification, protected path normalization, execution log entries,
and Windows Update service restart validation.

Current validation status:

```text
64 tests passed
0 tests failed
```

## Continuous Integration

GitHub Actions workflows are included for:

* PowerShell syntax checks
* Pester tests
* Markdown linting

The badges point to the GitHub Actions workflows for this repository.

## Project Layout

```text
.
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
├── deployment/
│   ├── configmgr/
│   ├── intune/
│   └── packaging/
├── docs/
│   ├── project-spec.md
│   ├── roadmap.md
│   ├── safety-rules.md
│   └── usage-examples.md
├── reports/
├── src/
│   ├── WinCleanAudit.ps1
│   └── modules/
├── tasks/
├── tests/Pester/
├── README.md
├── enterprisereadmin.md
├── SECURITY.md
├── CONTRIBUTING.md
├── changelog.md
├── assessment.md
├── completed-upgrades.md
└── future-upgrades.md
```

## Configuration

Main configuration file:

```text
tasks/windows-cleanup.yaml
```

This file controls enabled modules, report settings, safety settings, and
module-specific options.

Policy profiles are also selected there:

```yaml
execution:
  policy_profile: enterprise_audit
```

The `enterprise_audit` profile enables machine-readable exports and Event Log
output.

## Enterprise Deployment

Enterprise admin guidance is here:

[enterprisereadmin.md](enterprisereadmin.md)

Deployment templates are here:

[deployment/README.md](deployment/README.md)

Managed packaging templates are here:

[deployment/packaging/README.md](deployment/packaging/README.md)

The scheduled task installer is here:

```powershell
.\src\Install-WinCleanAuditScheduledTask.ps1 -Frequency Weekly -JsonReport -CsvReport
```

Scheduled DryRun tasks include `-NoBrowserLaunch` so automation does not open
the HTML report interactively.

Report retention is disabled by default.
Enable it in `tasks/windows-cleanup.yaml` when old generated files should be
removed automatically.

## Project Spec

The lightweight project spec is here:

[docs/project-spec.md](docs/project-spec.md)

## Upgrade Tracking

Completed work is tracked here:

[completed-upgrades.md](completed-upgrades.md)

Current repo status and risk notes are tracked here:

[assessment.md](assessment.md)

Repo changes are tracked here:

[changelog.md](changelog.md)

## Known Limitations

* Some inventory data depends on Windows version and user permissions.
* Browser cache cleanup may skip locked files if browsers are open.
* Windows Update cache cleanup requires administrator rights.
* Tests cover contracts, safety guards, protected paths, failure
  classification, execution logging, and Windows Update service restart
  validation.
  More destructive-path mock coverage is recommended before broad
  `-Execute` use.

## First-Time Recommendation

Run only this:

```powershell
.\src\WinCleanAudit.ps1 -DryRun
```

Read the HTML report that opens in your browser before using `-Execute`.

[powershell-tests-badge]: https://github.com/mickpletcher/windows-system-cleanup-tool/actions/workflows/powershell-tests.yml/badge.svg
[powershell-tests-workflow]: https://github.com/mickpletcher/windows-system-cleanup-tool/actions/workflows/powershell-tests.yml
[markdown-lint-badge]: https://github.com/mickpletcher/windows-system-cleanup-tool/actions/workflows/markdown-lint.yml/badge.svg
[markdown-lint-workflow]: https://github.com/mickpletcher/windows-system-cleanup-tool/actions/workflows/markdown-lint.yml
