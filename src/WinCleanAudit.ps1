[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Execute,
    [switch]$NoPrompt,
    [string]$ReportPath,
    [string]$ConfigPath = (Join-Path $PSScriptRoot '..\tasks\windows-cleanup.yaml')
)

$script:WinCleanAuditVersion = 'v1.0.0'

if ($NoPrompt -and -not $Execute) {
    throw '-NoPrompt can only be used with -Execute.'
}

if (-not $DryRun -and -not $Execute) {
    $DryRun = $true
}

$coreModules = @(
    'Results.psm1',
    'Safety.psm1',
    'Logging.psm1',
    'Configuration.psm1',
    'ModuleLoader.psm1',
    'Pipeline.psm1',
    'ReportWriter.psm1'
)

foreach ($module in $coreModules) {
    Import-Module -Name (Join-Path $PSScriptRoot "modules\$module") -Force
}

$config = Get-WCAConfiguration -ConfigPath $ConfigPath
$configCheck = Test-WCAConfiguration -Configuration $config
if (-not $configCheck.IsValid) {
    throw "Configuration invalid: $($configCheck.Errors -join '; ')"
}

$mode = if ($Execute) { 'Execute' } else { 'DryRun' }
$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$defaultLogPath = Join-Path $PSScriptRoot "..\reports\wincleanaudit-$runStamp.log"
Initialize-WCALogging -LogPath $defaultLogPath -Level $config.logging.level
Write-WCALog -Message "WinCleanAudit $script:WinCleanAuditVersion starting in mode $mode" -Level 'INFO'

$loadResult = Import-WCAModules -ModuleNames $config.modules.enabled
foreach ($loadError in $loadResult.Errors) {
    Write-WCAError -Message $loadError
}

$results = Invoke-WCAPipeline -Modules $config.modules.enabled -EntryPoints $config.modules.entry_points -DryRun:$DryRun -Execute:$Execute -NoPrompt:$NoPrompt

$report = New-WinCleanReport -Mode $mode -Results $results
$null = Add-ReportSection -Report $report -Name 'Execution' -Content $results

if (-not $ReportPath) {
    $ReportPath = Join-Path $PSScriptRoot "..\$($config.reporting.output_folder)"
}

$writtenReport = Write-MarkdownReport -Report $report -OutputFolder $ReportPath
Write-WCALog -Message "Report written: $writtenReport" -Level 'SUCCESS'
Close-WCALog

[PSCustomObject]@{
    Version = $script:WinCleanAuditVersion
    Mode    = $mode
    Report  = $writtenReport
    Results = $results
}
