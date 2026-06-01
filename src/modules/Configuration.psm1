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
            }
            reporting = [PSCustomObject]@{
                output_folder = 'reports'
            }
            logging = [PSCustomObject]@{
                level = 'INFO'
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
    if (-not $config.reporting.output_folder) {
        $config.reporting.output_folder = 'reports'
    }
    if (-not $config.modules.enabled) {
        $config.modules.enabled = @()
    }
    if (-not $config.modules.entry_points) {
        $config.modules | Add-Member -NotePropertyName entry_points -NotePropertyValue ([PSCustomObject]$defaultEntryPoints) -Force
    }

    return $config
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

Export-ModuleMember -Function Get-WCAConfiguration, Test-WCAConfiguration
