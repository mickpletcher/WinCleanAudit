<#
.SYNOPSIS
Registers a recurring WinCleanAudit DryRun scheduled task.

.DESCRIPTION
Creates or replaces a scheduled task that runs WinCleanAudit in DryRun mode.
The task always includes -NoBrowserLaunch so managed automation does not open
the HTML report interactively.

Use -JsonReport and -CsvReport when reports need to be collected by Intune,
ConfigMgr, or another enterprise reporting pipeline.

.PARAMETER TaskName
Name of the scheduled task. Defaults to WinCleanAudit DryRun.

.PARAMETER ScriptPath
Path to WinCleanAudit.ps1.

.PARAMETER ConfigPath
Path to tasks/windows-cleanup.yaml.

.PARAMETER ReportPath
Folder where scheduled task reports are written.

.PARAMETER Frequency
Scheduled task cadence. Valid values are Daily and Weekly.

.PARAMETER At
Scheduled task start time.

.PARAMETER JsonReport
Adds -JsonReport to the scheduled task command.

.PARAMETER CsvReport
Adds -CsvReport to the scheduled task command.

.PARAMETER RunAsSystem
Registers the task to run as SYSTEM with highest privileges.

.EXAMPLE
.\Install-WinCleanAuditScheduledTask.ps1 -Frequency Weekly -JsonReport -CsvReport

Registers a weekly DryRun task with JSON and CSV exports.

.EXAMPLE
.\Install-WinCleanAuditScheduledTask.ps1 -Frequency Weekly -JsonReport -CsvReport -RunAsSystem

Registers a managed weekly DryRun task under SYSTEM.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$TaskName = 'WinCleanAudit DryRun',
    [string]$ScriptPath = (Join-Path $PSScriptRoot 'WinCleanAudit.ps1'),
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\tasks\windows-cleanup.yaml'),
    [string]$ReportPath = (Join-Path $PSScriptRoot '..\reports'),
    [ValidateSet('Daily','Weekly')]
    [string]$Frequency = 'Weekly',
    [datetime]$At = '3:00 AM',
    [switch]$JsonReport,
    [switch]$CsvReport,
    [switch]$RunAsSystem
)

if (-not (Test-Path $ScriptPath)) {
    throw "ScriptPath not found: $ScriptPath"
}
if (-not (Test-Path $ConfigPath)) {
    throw "ConfigPath not found: $ConfigPath"
}

$arguments = @(
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-File',
    "`"$ScriptPath`"",
    '-DryRun',
    '-NoBrowserLaunch',
    '-ConfigPath',
    "`"$ConfigPath`"",
    '-ReportPath',
    "`"$ReportPath`""
)
if ($JsonReport) {
    $arguments += '-JsonReport'
}
if ($CsvReport) {
    $arguments += '-CsvReport'
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument ($arguments -join ' ')
$trigger = if ($Frequency -eq 'Daily') {
    New-ScheduledTaskTrigger -Daily -At $At
}
else {
    New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At $At
}
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew
$principal = if ($RunAsSystem) {
    New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
}
else {
    New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel LeastPrivilege
}

if ($PSCmdlet.ShouldProcess($TaskName, 'Register WinCleanAudit scheduled task')) {
    Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force
}
