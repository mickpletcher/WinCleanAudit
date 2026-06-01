function Get-WCAAvailableModules {
    [CmdletBinding()]
    param(
        [string]$ModuleRoot = $PSScriptRoot
    )

    Get-ChildItem -Path $ModuleRoot -Filter '*.psm1' -File |
        Where-Object { $_.BaseName -notin @('Configuration','Logging','ModuleLoader','Pipeline','ReportWriter','Results','Safety') } |
        Select-Object -ExpandProperty BaseName
}

function Import-WCAModules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ModuleNames,
        [string]$ModuleRoot = $PSScriptRoot
    )

    $loaded = @()
    $errors = @()

    foreach ($name in $ModuleNames) {
        $path = Join-Path $ModuleRoot "$name.psm1"
        if (-not (Test-Path $path)) {
            $errors += "Module file missing: $path"
            continue
        }

        try {
            Import-Module -Name $path -Force -Global -ErrorAction Stop
            $loaded += $name
        }
        catch {
            $errors += "Failed to import ${name}: $($_.Exception.Message)"
        }
    }

    [PSCustomObject]@{
        Loaded = $loaded
        Errors = $errors
    }
}

Export-ModuleMember -Function Import-WCAModules, Get-WCAAvailableModules
