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
