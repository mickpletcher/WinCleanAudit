<#
.SYNOPSIS
Remediates WinCleanAudit recurring audit compliance for ConfigMgr baselines.

.DESCRIPTION
Re-registers the WinCleanAudit scheduled DryRun task and runs a DryRun with
-NoBrowserLaunch, JSON export, and CSV export. Use only after piloting the
compliance baseline.

.PARAMETER InstallRoot
WinCleanAudit install root. Defaults to ProgramData\WinCleanAudit.

.PARAMETER TaskName
Scheduled task name to register. Defaults to WinCleanAudit DryRun.

.EXAMPLE
.\remediation.ps1

Repairs the default scheduled task and generates fresh DryRun reports.
#>
[CmdletBinding()]
param(
    [string]$InstallRoot = "$env:ProgramData\WinCleanAudit",
    [string]$TaskName = 'WinCleanAudit DryRun'
)

$installer = Join-Path $InstallRoot 'src\Install-WinCleanAuditScheduledTask.ps1'
$scriptPath = Join-Path $InstallRoot 'src\WinCleanAudit.ps1'
$configPath = Join-Path $InstallRoot 'tasks\windows-cleanup.yaml'
$reportPath = Join-Path $InstallRoot 'reports'

if (-not (Test-Path $installer)) {
    throw "Scheduled task installer missing: $installer"
}
if (-not (Test-Path $scriptPath)) {
    throw "WinCleanAudit script missing: $scriptPath"
}
if (-not (Test-Path $configPath)) {
    throw "WinCleanAudit config missing: $configPath"
}

& $installer `
    -TaskName $TaskName `
    -ScriptPath $scriptPath `
    -ConfigPath $configPath `
    -ReportPath $reportPath `
    -Frequency Weekly `
    -JsonReport `
    -CsvReport `
    -RunAsSystem

& $scriptPath `
    -DryRun `
    -NoBrowserLaunch `
    -JsonReport `
    -CsvReport `
    -ConfigPath $configPath `
    -ReportPath $reportPath | Out-Null
