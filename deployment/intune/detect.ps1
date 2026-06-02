$installRoot = "$env:ProgramData\WinCleanAudit"
$scriptPath = Join-Path $installRoot 'src\WinCleanAudit.ps1'
$configPath = Join-Path $installRoot 'tasks\windows-cleanup.yaml'

if ((Test-Path $scriptPath) -and (Test-Path $configPath)) {
    Write-Output 'WinCleanAudit installed'
    exit 0
}

Write-Output 'WinCleanAudit not installed'
exit 1
