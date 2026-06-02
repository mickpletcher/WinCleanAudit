<#
.SYNOPSIS
Runs a safe Windows cleanup audit or approved cleanup workflow.

.DESCRIPTION
WinCleanAudit scans configured Windows cleanup and inventory modules, writes
Markdown reports, and can optionally write HTML, JSON, and CSV reports.

DryRun is the default mode. DryRun does not delete files. Execute mode requires
the -Execute switch and still respects protected user data, cloud sync, source
code, redirected known folder, and enterprise Folder Redirection protections.

Execute mode records attempted deletes, skipped cleanup items, and service
actions in ExecutionLog. Windows Update cache cleanup validates service restart
state after cleanup.

.PARAMETER DryRun
Runs audit mode. This is the default when neither -DryRun nor -Execute is
provided.

.PARAMETER Execute
Runs approved cleanup actions. Destructive actions prompt unless -NoPrompt is
also supplied.

.PARAMETER NoPrompt
Suppresses confirmation prompts in Execute mode. This switch is rejected unless
-Execute is also supplied.

.PARAMETER NoBrowserLaunch
Suppresses automatic HTML report launch during DryRun. Use this for scheduled
tasks, Intune, ConfigMgr, and other automation.

.PARAMETER JsonReport
Writes a JSON report with the full structured report object.

.PARAMETER CsvReport
Writes a CSV report with one summary row per module.

.PARAMETER ReportPath
Overrides the report output folder.

.PARAMETER ConfigPath
Specifies the YAML configuration file. Defaults to tasks/windows-cleanup.yaml.

.EXAMPLE
.\WinCleanAudit.ps1 -DryRun

Runs a safe audit and opens the HTML report.

.EXAMPLE
.\WinCleanAudit.ps1 -DryRun -NoBrowserLaunch -JsonReport -CsvReport

Runs an automation friendly audit and writes machine readable exports.

.EXAMPLE
.\WinCleanAudit.ps1 -Execute

Runs cleanup mode with confirmation prompts.

.EXAMPLE
.\WinCleanAudit.ps1 -Execute -NoPrompt

Runs cleanup mode without prompts. Use only after tested DryRun review.

.NOTES
Generated reports and logs are written under reports/ by default and should not
be committed to source control.
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Execute,
    [switch]$NoPrompt,
    [switch]$NoBrowserLaunch,
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
    if (-not $NoBrowserLaunch) {
        Start-Process -FilePath $writtenHtmlReport
    }
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
