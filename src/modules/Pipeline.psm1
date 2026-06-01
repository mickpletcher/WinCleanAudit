function Get-WCAEntryPoint {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$EntryPoints,
        [Parameter(Mandatory)]
        [string]$ModuleName
    )

    if ($EntryPoints -is [hashtable] -and $EntryPoints.ContainsKey($ModuleName)) {
        return [string]$EntryPoints[$ModuleName]
    }

    $property = $EntryPoints.PSObject.Properties[$ModuleName]
    if ($property) {
        return [string]$property.Value
    }

    throw "No configured entry point exists for module: $ModuleName"
}

function Invoke-WCAModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        [Parameter(Mandatory)]
        [object]$EntryPoints,
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt
    )

    $start = Get-Date

    try {
        $commandName = Get-WCAEntryPoint -EntryPoints $EntryPoints -ModuleName $ModuleName
        $command = Get-Command -Name $commandName -ErrorAction Stop
        $params = @{
            DryRun   = [bool]$DryRun
            Execute  = [bool]$Execute
            NoPrompt = [bool]$NoPrompt
        }

        $result = & $command @params
        if ($null -eq $result.Duration) {
            $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
        }
        return $result
    }
    catch {
        $duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
        [PSCustomObject]@{
            TaskName        = $ModuleName
            Module          = $ModuleName
            Status          = 'Error'
            Mode            = if ($Execute) { 'Execute' } else { 'DryRun' }
            ItemsScanned    = 0
            ItemsModified   = 0
            EstimatedBytes  = [Int64]0
            RecoveredBytes  = [Int64]0
            ActionsTaken    = @()
            Warnings        = @()
            Errors          = @($_.Exception.Message)
            Recommendations = @('Review module implementation and retry.')
            Details         = @()
            Duration        = $duration
        }
    }
}

function Invoke-WCAPipeline {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$Modules,
        [Parameter(Mandatory)]
        [object]$EntryPoints,
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt
    )

    $results = @()
    foreach ($module in $Modules) {
        $results += Invoke-WCAModule -ModuleName $module -EntryPoints $EntryPoints -DryRun:$DryRun -Execute:$Execute -NoPrompt:$NoPrompt
    }

    return $results
}

Export-ModuleMember -Function Invoke-WCAPipeline, Invoke-WCAModule
