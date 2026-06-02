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
* Generate Markdown and HTML reports you can review later.

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
```

## Run Modes

### DryRun

Safe audit mode.

```powershell
.\src\WinCleanAudit.ps1 -DryRun
```

Use this first. It scans, writes reports, and opens the HTML report in your
browser. It does not delete anything.

### Execute

Cleanup mode.

```powershell
.\src\WinCleanAudit.ps1 -Execute
```

This can delete approved cleanup targets after confirmation.

Use this only after reading the DryRun report.

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

For a normal first run, look for:

* `Mode`: should be `DryRun`
* `Errors`: anything that failed
* `Warnings`: access denied, locked files, or skipped paths
* `Recommendations`: items to review manually

## Administrator Notes

Some checks work better when PowerShell is run as administrator.

Windows Update cache cleanup requires administrator rights in execute mode.

For normal review, start without admin rights and use `-DryRun`.

## Testing

Run tests with:

```powershell
Invoke-Pester -Path .\tests\Pester
```

The test suite checks imports, DryRun behavior, output shape, and safety guards.

Current validation status:

```text
38 tests passed
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
├── .github/workflows/
├── docs/
├── reports/
├── src/
│   ├── WinCleanAudit.ps1
│   └── modules/
├── tasks/
├── tests/Pester/
├── README.md
├── SECURITY.md
├── CONTRIBUTING.md
├── changelog.md
├── assessment.md
└── completed-upgrades.md
```

## Configuration

Main configuration file:

```text
tasks/windows-cleanup.yaml
```

This file controls enabled modules, report settings, safety settings, and
module-specific options.

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
* Tests currently focus on contracts and safety guards.
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
