$installRoot = "$env:ProgramData\WinCleanAudit"
$scriptPath = Join-Path $installRoot 'src\WinCleanAudit.ps1'
$configPath = Join-Path $installRoot 'tasks\windows-cleanup.yaml'

if ((Test-Path $scriptPath) -and (Test-Path $configPath)) {
    Write-Output 'Installed'
}
