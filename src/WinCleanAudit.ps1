[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Execute,
    [switch]$NoPrompt,
    [switch]$JsonReport,
    [switch]$CsvReport,
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
$policyProfile = Get-WCAPolicyProfile -Configuration $config

$mode = if ($Execute) { 'Execute' } else { 'DryRun' }
$runStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$defaultLogPath = Join-Path $PSScriptRoot "..\reports\wincleanaudit-$runStamp.log"
Initialize-WCALogging -LogPath $defaultLogPath -Level $config.logging.level -EventLogEnabled ([bool]$policyProfile.Profile.logging.event_log_enabled -or [bool]$config.logging.event_log.enabled) -EventLogName $config.logging.event_log.log_name -EventLogSource $config.logging.event_log.source
Write-WCALog -Message "WinCleanAudit $script:WinCleanAuditVersion starting in mode $mode" -Level 'INFO'
Write-WCALog -Message "Policy profile: $($policyProfile.Name)" -Level 'INFO'

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

$reportStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$writtenReport = Write-MarkdownReport -Report $report -OutputFolder $ReportPath -Timestamp $reportStamp
Write-WCALog -Message "Report written: $writtenReport" -Level 'SUCCESS'

$writtenHtmlReport = $null
if ($DryRun) {
    $writtenHtmlReport = Write-HtmlReport -Report $report -OutputFolder $ReportPath -Timestamp $reportStamp
    Write-WCALog -Message "HTML report written: $writtenHtmlReport" -Level 'SUCCESS'
    Start-Process -FilePath $writtenHtmlReport
}

$writtenJsonReport = $null
if ($JsonReport -or [bool]$config.reporting.json_export -or [bool]$policyProfile.Profile.reporting.json_export) {
    $writtenJsonReport = Write-JsonReport -Report $report -OutputFolder $ReportPath -Timestamp $reportStamp
    Write-WCALog -Message "JSON report written: $writtenJsonReport" -Level 'SUCCESS'
}

$writtenCsvReport = $null
if ($CsvReport -or [bool]$config.reporting.csv_export -or [bool]$policyProfile.Profile.reporting.csv_export) {
    $writtenCsvReport = Write-CsvReport -Report $report -OutputFolder $ReportPath -Timestamp $reportStamp
    Write-WCALog -Message "CSV report written: $writtenCsvReport" -Level 'SUCCESS'
}

$retentionResult = $null
if ([bool]$config.reporting.retention.enabled) {
    $retentionDays = if ($policyProfile.Profile.reporting.retention_days) {
        [int]$policyProfile.Profile.reporting.retention_days
    }
    elseif ($config.reporting.retention.days) {
        [int]$config.reporting.retention.days
    }
    else {
        30
    }
    $retentionResult = Remove-OldWCAReports -OutputFolder $ReportPath -RetentionDays $retentionDays -IncludeExtensions $config.reporting.retention.include_extensions
    Write-WCALog -Message "Report retention removed $($retentionResult.Removed) old files." -Level 'INFO'
}

Close-WCALog

[PSCustomObject]@{
    Version         = $script:WinCleanAuditVersion
    Mode            = $mode
    PolicyProfile   = $policyProfile.Name
    Report          = $writtenReport
    HtmlReport      = $writtenHtmlReport
    JsonReport      = $writtenJsonReport
    CsvReport       = $writtenCsvReport
    RetentionResult = $retentionResult
    Results         = $results
}
