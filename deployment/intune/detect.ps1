<#
.SYNOPSIS
Detects WinCleanAudit installation health for Intune.

.DESCRIPTION
Validates that WinCleanAudit is installed, the configuration file exists, the
scheduled DryRun task is registered, and a recent JSON report exists.

The script exits 0 when compliant and exits 1 when any required condition is
missing. It writes missing checks to output for Intune detection diagnostics.

.PARAMETER InstallRoot
WinCleanAudit install root. Defaults to ProgramData\WinCleanAudit.

.PARAMETER TaskName
Scheduled task name to verify. Defaults to WinCleanAudit DryRun.

.PARAMETER RecentReportDays
Maximum age in days for a valid cleanup-report-*.json report.

.EXAMPLE
.\detect.ps1

Runs default Intune detection checks.

.EXAMPLE
.\detect.ps1 -RecentReportDays 7

Requires a JSON report from the last seven days.
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
    $errors += "Script missing: $scriptPath"
}
if (-not (Test-Path $configPath)) {
    $errors += "Config missing: $configPath"
}

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $task) {
    $errors += "Scheduled task missing: $TaskName"
}

$cutoff = (Get-Date).AddDays(-$RecentReportDays)
$recentReport = Get-ChildItem -Path $reportPath -Filter 'cleanup-report-*.json' -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -ge $cutoff } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $recentReport) {
    $errors += "No cleanup-report-*.json newer than $RecentReportDays days in $reportPath"
}

if ($errors.Count -eq 0) {
    Write-Output 'WinCleanAudit installed and recently reporting'
    exit 0
}

Write-Output ($errors -join '; ')
exit 1
