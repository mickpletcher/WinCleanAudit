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
