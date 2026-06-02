<#
.SYNOPSIS
Discovers WinCleanAudit recurring audit compliance for ConfigMgr baselines.

.DESCRIPTION
Checks script presence, config presence, scheduled task registration, and
recent JSON report generation. Outputs Compliant when all checks pass.
Otherwise outputs NonCompliant with comma separated reason codes.

.PARAMETER InstallRoot
WinCleanAudit install root. Defaults to ProgramData\WinCleanAudit.

.PARAMETER TaskName
Scheduled task name to verify. Defaults to WinCleanAudit DryRun.

.PARAMETER RecentReportDays
Maximum age in days for a valid cleanup-report-*.json report.

.EXAMPLE
.\detection.ps1

Runs default compliance discovery.
#>
[CmdletBinding()]
param(
    [string]$InstallRoot = "$env:ProgramData\WinCleanAudit",
    [string]$TaskName = 'WinCleanAudit DryRun',
    [int]$RecentReportDays = 14
)

$scriptPath = Join-Path $InstallRoot 'src\WinCleanAudit.ps1'
$configPath = Join-Path $InstallRoot 'tasks\windows-cleanup.yaml'
$reportPath = Join-Path $InstallRoot 'reports'
$errors = @()

if (-not (Test-Path $scriptPath)) {
    $errors += 'ScriptMissing'
}
if (-not (Test-Path $configPath)) {
    $errors += 'ConfigMissing'
}
if (-not (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue)) {
    $errors += 'ScheduledTaskMissing'
}

$cutoff = (Get-Date).AddDays(-$RecentReportDays)
$recentReport = Get-ChildItem -Path $reportPath -Filter 'cleanup-report-*.json' -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $cutoff } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $recentReport) {
    $errors += 'RecentReportMissing'
}

if ($errors.Count -eq 0) {
    'Compliant'
}
else {
    "NonCompliant:$($errors -join ',')"
}
