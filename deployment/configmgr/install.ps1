<#
.SYNOPSIS
Installs WinCleanAudit for ConfigMgr application deployment.

.DESCRIPTION
Copies the WinCleanAudit source and task configuration into the install root.
When -RegisterScheduledTask is supplied, registers a weekly managed DryRun task
with -NoBrowserLaunch, JSON export, CSV export, and SYSTEM context.

.PARAMETER InstallRoot
Destination folder for WinCleanAudit. Defaults to ProgramData\WinCleanAudit.

.PARAMETER RegisterScheduledTask
Registers the recurring WinCleanAudit DryRun scheduled task after copying
files.

.EXAMPLE
.\install.ps1

Copies WinCleanAudit files to the default install root.

.EXAMPLE
.\install.ps1 -RegisterScheduledTask

Copies WinCleanAudit files and registers the managed recurring DryRun task.
#>
[CmdletBinding()]
param(
    [string]$InstallRoot = "$env:ProgramData\WinCleanAudit",
    [switch]$RegisterScheduledTask
)

$sourceRoot = Split-Path -Path $PSScriptRoot -Parent | Split-Path -Parent

if (-not (Test-Path $InstallRoot)) {
    New-Item -Path $InstallRoot -ItemType Directory -Force | Out-Null
}

Copy-Item -Path (Join-Path $sourceRoot 'src') -Destination $InstallRoot -Recurse -Force
Copy-Item -Path (Join-Path $sourceRoot 'tasks') -Destination $InstallRoot -Recurse -Force

if ($RegisterScheduledTask) {
    & (Join-Path $InstallRoot 'src\Install-WinCleanAuditScheduledTask.ps1') `
        -ScriptPath (Join-Path $InstallRoot 'src\WinCleanAudit.ps1') `
        -ConfigPath (Join-Path $InstallRoot 'tasks\windows-cleanup.yaml') `
        -ReportPath (Join-Path $InstallRoot 'reports') `
        -Frequency Weekly `
        -JsonReport `
        -CsvReport `
        -RunAsSystem
}
