# WinCleanAudit Project Spec

## Purpose

WinCleanAudit is a safe Windows cleanup and audit tool written in PowerShell.

It helps users find wasted disk space, risky startup entries, old logs, large
files, duplicate downloads, installed apps, browser cache usage, Recycle Bin
usage, Windows Update cache usage, and basic disk health signals.

## Non Goals

WinCleanAudit does not silently delete files.

WinCleanAudit does not clean user data folders, source code folders, or cloud
sync folders.

WinCleanAudit does not clean browser passwords, cookies, history, bookmarks, or
profile data.

WinCleanAudit does not replace enterprise endpoint management, backup, EDR, or
configuration management tools.

## Safety Rules

DryRun is the default mode.

Cleanup requires explicit `-Execute`.

`-NoPrompt` is allowed only with `-Execute`.

`-NoBrowserLaunch` suppresses the DryRun HTML browser launch for automation.

Protected paths are always excluded.

Module failures must be reported and must not stop the full run.

Execute mode must still respect protected path rules.

Execute mode records attempted deletes, skipped cleanup items, and service
actions in `ExecutionLog`.

Windows Update cache cleanup validates that services running before cleanup are
running again after restart.

## Report Contract

Markdown reports are always written.

DryRun also writes an HTML report and opens it in the default browser unless
`-NoBrowserLaunch` is used.

JSON and CSV reports are optional and are written only when requested.

Reports are written under `reports/` by default.

Generated reports and logs must not be committed.

Report retention is optional and disabled by default.

## Enterprise Contract

Policy profiles centralize fleet defaults in `tasks/windows-cleanup.yaml`.

Scheduled task installation is optional and managed by
`src/Install-WinCleanAuditScheduledTask.ps1`.

Intune and ConfigMgr starter templates live under `deployment/`.

Windows Event Log output is optional and disabled by default.

## Module Contract

Each module returns a structured result object:

```powershell
[PSCustomObject]@{
    TaskName        = ""
    Module          = ""
    Status          = "Success|Warning|Error|Skipped"
    Mode            = "DryRun|Execute"
    ItemsScanned    = 0
    ItemsModified   = 0
    EstimatedBytes  = 0
    RecoveredBytes  = 0
    ActionsTaken    = @()
    Warnings        = @()
    Errors          = @()
    Recommendations = @()
    Details         = @()
    ExecutionLog    = @()
    Duration        = 0
}
```

## Release Criteria

PowerShell syntax check passes for all `.ps1` and `.psm1` files.

Pester passes.

DryRun completes.

Markdown and HTML reports are generated.

Optional JSON and CSV report exports work when requested or enabled by policy.

Generated reports and logs are not staged.

Documentation matches current behavior.
