function Get-WCAConfiguration {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Join-Path $PSScriptRoot '..\..\tasks\windows-cleanup.yaml')
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }

    $defaultEntryPoints = [ordered]@{
        TempCleanup        = 'Invoke-TempCleanup'
        WindowsUpdateCache = 'Invoke-WindowsUpdateCacheTask'
        RecycleBin         = 'Invoke-RecycleBinCleanup'
        OldLogCleanup      = 'Invoke-OldLogCleanup'
        BrowserCache       = 'Invoke-BrowserCacheCleanup'
        StartupInventory   = 'Invoke-StartupInventory'
        LargeFileReport    = 'Invoke-LargeFileReport'
        DuplicateDownloads = 'Invoke-DuplicateDownloadsReport'
        InstalledApps      = 'Invoke-InstalledAppsInventory'
        DiskHealth         = 'Invoke-DiskHealthReport'
    }

    $raw = Get-Content -Path $ConfigPath -Raw
    if (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue) {
        $config = $raw | ConvertFrom-Yaml
    }
    else {
        $enabledModules = @()
        $entryPoints = [ordered]@{}
        $lines = $raw -split "`r?`n"
        $inEnabledBlock = $false
        $inEntryPointBlock = $false
        foreach ($line in $lines) {
            if ($line -match '^\s*enabled:\s*$' -and -not $inEnabledBlock) {
                $inEnabledBlock = $true
                $inEntryPointBlock = $false
                continue
            }
            if ($line -match '^\s*entry_points:\s*$') {
                $inEntryPointBlock = $true
                $inEnabledBlock = $false
                continue
            }
            if ($inEnabledBlock -and $line -match '^\s*-\s*(.+?)\s*$') {
                $enabledModules += $Matches[1]
                continue
            }
            if ($inEntryPointBlock -and $line -match '^\s{4}([^:]+):\s*(.+?)\s*$') {
                $entryPoints[$Matches[1].Trim()] = $Matches[2].Trim()
                continue
            }
            if ($inEnabledBlock -and $line -match '^\S') {
                $inEnabledBlock = $false
            }
            if ($inEntryPointBlock -and $line -match '^\S') {
                $inEntryPointBlock = $false
            }
        }

        $config = [PSCustomObject]@{
            application = [PSCustomObject]@{
                name    = 'WinCleanAudit'
                version = '1.0.0'
            }
            execution = [PSCustomObject]@{
                default_mode = 'DryRun'
                policy_profile = 'default'
            }
            reporting = [PSCustomObject]@{
                output_folder = 'reports'
                json_export = $false
                csv_export = $false
                retention = [PSCustomObject]@{
                    enabled = $false
                    days = 30
                    include_extensions = @('.md','.html','.json','.csv','.log')
                }
            }
            logging = [PSCustomObject]@{
                level = 'INFO'
                event_log = [PSCustomObject]@{
                    enabled = $false
                    log_name = 'Application'
                    source = 'WinCleanAudit'
                }
            }
            policy_profiles = [PSCustomObject]@{
                default = [PSCustomObject]@{
                    description = 'Standard local audit profile.'
                    reporting = [PSCustomObject]@{
                        json_export = $false
                        csv_export = $false
                        retention_days = 30
                    }
                    logging = [PSCustomObject]@{
                        event_log_enabled = $false
                    }
                }
                enterprise_audit = [PSCustomObject]@{
                    description = 'Endpoint fleet audit profile with machine-readable exports.'
                    reporting = [PSCustomObject]@{
                        json_export = $true
                        csv_export = $true
                        retention_days = 14
                    }
                    logging = [PSCustomObject]@{
                        event_log_enabled = $true
                    }
                }
                local_quiet = [PSCustomObject]@{
                    description = 'Local profile with minimal report exports.'
                    reporting = [PSCustomObject]@{
                        json_export = $false
                        csv_export = $false
                        retention_days = 7
                    }
                    logging = [PSCustomObject]@{
                        event_log_enabled = $false
                    }
                }
            }
            modules = [PSCustomObject]@{
                enabled = if ($enabledModules.Count -gt 0) { $enabledModules } else { @(
                    'TempCleanup',
                    'WindowsUpdateCache',
                    'RecycleBin',
                    'OldLogCleanup',
                    'BrowserCache',
                    'StartupInventory',
                    'LargeFileReport',
                    'DuplicateDownloads',
                    'InstalledApps',
                    'DiskHealth'
                ) }
                entry_points = if ($entryPoints.Count -gt 0) { [PSCustomObject]$entryPoints } else { [PSCustomObject]$defaultEntryPoints }
            }
        }
    }

    if (-not $config.execution.default_mode) {
        $config.execution.default_mode = 'DryRun'
    }
    if (-not $config.execution.policy_profile) {
        $config.execution | Add-Member -NotePropertyName policy_profile -NotePropertyValue 'default' -Force
    }
    if (-not $config.reporting.output_folder) {
        $config.reporting.output_folder = 'reports'
    }
    if ($null -eq $config.reporting.json_export) {
        $config.reporting | Add-Member -NotePropertyName json_export -NotePropertyValue $false -Force
    }
    if ($null -eq $config.reporting.csv_export) {
        $config.reporting | Add-Member -NotePropertyName csv_export -NotePropertyValue $false -Force
    }
    if (-not $config.reporting.retention) {
        $config.reporting | Add-Member -NotePropertyName retention -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    if ($null -eq $config.reporting.retention.enabled) {
        $config.reporting.retention | Add-Member -NotePropertyName enabled -NotePropertyValue $false -Force
    }
    if (-not $config.reporting.retention.days) {
        $config.reporting.retention | Add-Member -NotePropertyName days -NotePropertyValue 30 -Force
    }
    if (-not $config.reporting.retention.include_extensions) {
        $config.reporting.retention | Add-Member -NotePropertyName include_extensions -NotePropertyValue @('.md','.html','.json','.csv','.log') -Force
    }
    if (-not $config.logging.event_log) {
        $config.logging | Add-Member -NotePropertyName event_log -NotePropertyValue ([PSCustomObject]@{}) -Force
    }
    if ($null -eq $config.logging.event_log.enabled) {
        $config.logging.event_log | Add-Member -NotePropertyName enabled -NotePropertyValue $false -Force
    }
    if (-not $config.logging.event_log.log_name) {
        $config.logging.event_log | Add-Member -NotePropertyName log_name -NotePropertyValue 'Application' -Force
    }
    if (-not $config.logging.event_log.source) {
        $config.logging.event_log | Add-Member -NotePropertyName source -NotePropertyValue 'WinCleanAudit' -Force
    }
    if (-not $config.policy_profiles) {
        $config | Add-Member -NotePropertyName policy_profiles -NotePropertyValue ([PSCustomObject]@{
            default = [PSCustomObject]@{
                description = 'Standard local audit profile.'
                reporting = [PSCustomObject]@{
                    json_export = $false
                    csv_export = $false
                    retention_days = 30
                }
                logging = [PSCustomObject]@{
                    event_log_enabled = $false
                }
            }
        }) -Force
    }
    if (-not $config.policy_profiles.PSObject.Properties['enterprise_audit']) {
        $config.policy_profiles | Add-Member -NotePropertyName enterprise_audit -NotePropertyValue ([PSCustomObject]@{
            description = 'Endpoint fleet audit profile with machine-readable exports.'
            reporting = [PSCustomObject]@{
                json_export = $true
                csv_export = $true
                retention_days = 14
            }
            logging = [PSCustomObject]@{
                event_log_enabled = $true
            }
        }) -Force
    }
    if (-not $config.policy_profiles.PSObject.Properties['local_quiet']) {
        $config.policy_profiles | Add-Member -NotePropertyName local_quiet -NotePropertyValue ([PSCustomObject]@{
            description = 'Local profile with minimal report exports.'
            reporting = [PSCustomObject]@{
                json_export = $false
                csv_export = $false
                retention_days = 7
            }
            logging = [PSCustomObject]@{
                event_log_enabled = $false
            }
        }) -Force
    }
    if (-not $config.modules.enabled) {
        $config.modules.enabled = @()
    }
    if (-not $config.modules.entry_points) {
        $config.modules | Add-Member -NotePropertyName entry_points -NotePropertyValue ([PSCustomObject]$defaultEntryPoints) -Force
    }

    return $config
}

function Get-WCAPolicyProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Configuration
    )

    $profileName = if ($Configuration.execution.policy_profile) {
        $Configuration.execution.policy_profile
    }
    else {
        'default'
    }

    $profile = $Configuration.policy_profiles.PSObject.Properties[$profileName].Value
    if (-not $profile) {
        throw "Policy profile not found: $profileName"
    }

    return [PSCustomObject]@{
        Name = $profileName
        Profile = $profile
    }
}

function Test-WCAConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Configuration
    )

    $errors = @()
    if (-not $Configuration.application.name) {
        $errors += 'application.name is required'
    }
    if (-not $Configuration.execution.default_mode) {
        $errors += 'execution.default_mode is required'
    }
    if (-not $Configuration.execution.policy_profile) {
        $errors += 'execution.policy_profile is required'
    }
    elseif (-not $Configuration.policy_profiles.PSObject.Properties[$Configuration.execution.policy_profile]) {
        $errors += "policy_profiles.$($Configuration.execution.policy_profile) is required"
    }
    if (-not $Configuration.modules.enabled) {
        $errors += 'modules.enabled is required'
    }
    if (-not $Configuration.modules.entry_points) {
        $errors += 'modules.entry_points is required'
    }
    foreach ($module in @($Configuration.modules.enabled)) {
        if (-not $Configuration.modules.entry_points.PSObject.Properties[$module]) {
            $errors += "modules.entry_points.$module is required"
        }
    }

    return [PSCustomObject]@{
        IsValid = ($errors.Count -eq 0)
        Errors  = $errors
    }
}

Export-ModuleMember -Function Get-WCAConfiguration, Get-WCAPolicyProfile, Test-WCAConfiguration
