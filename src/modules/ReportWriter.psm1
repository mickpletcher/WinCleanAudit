function ConvertTo-ReadableSize {
    [CmdletBinding()]
    param(
        [Nullable[Int64]]$Bytes
    )

    if ($null -eq $Bytes -or $Bytes -le 0) {
        return '0 B'
    }

    $units = @('B','KB','MB','GB','TB')
    $size = [double]$Bytes
    $idx = 0
    while ($size -ge 1024 -and $idx -lt ($units.Count - 1)) {
        $size = $size / 1024
        $idx++
    }

    return ('{0:N2} {1}' -f $size, $units[$idx])
}

function New-WinCleanReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('DryRun','Execute')]
        [string]$Mode,
        [Parameter(Mandatory)]
        [object[]]$Results
    )

    [PSCustomObject]@{
        ComputerName      = $env:COMPUTERNAME
        UserName          = [Environment]::UserName
        DateTime          = Get-Date
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Mode              = $Mode
        Results           = $Results
        Sections          = @()
        ActionsTaken      = @($Results.ActionsTaken | Where-Object { $_ })
        Errors            = @($Results.Errors | Where-Object { $_ })
        Recommendations   = @($Results.Recommendations | Where-Object { $_ })
    }
}

function Add-ReportSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Report,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [object]$Content
    )

    $Report.Sections += [PSCustomObject]@{
        Name    = $Name
        Content = $Content
    }

    return $Report
}

function Write-MarkdownReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Report,
        [string]$OutputFolder = 'reports'
    )

    if (-not (Test-Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    $fileName = 'cleanup-report-{0}.md' -f (Get-Date -Format 'yyyyMMdd-HHmmss')
    $path = Join-Path $OutputFolder $fileName

    $lines = @()
    $lines += '# WinCleanAudit Report'
    $lines += ''
    $lines += '| Field | Value |'
    $lines += '|---|---|'
    $lines += "| Computer | $($Report.ComputerName) |"
    $lines += "| User | $($Report.UserName) |"
    $lines += "| Date | $($Report.DateTime) |"
    $lines += "| PowerShell | $($Report.PowerShellVersion) |"
    $lines += "| Mode | $($Report.Mode) |"
    $lines += ''
    $lines += '## Summary'
    $lines += ''
    $lines += '| Module | Status | Items Scanned | Items Modified | Estimated | Recovered |'
    $lines += '|---|---|---:|---:|---:|---:|'

    foreach ($result in $Report.Results) {
        $lines += "| $($result.Module) | $($result.Status) | $($result.ItemsScanned) | $($result.ItemsModified) | $(ConvertTo-ReadableSize -Bytes $result.EstimatedBytes) | $(ConvertTo-ReadableSize -Bytes $result.RecoveredBytes) |"
    }

    foreach ($result in $Report.Results) {
        $lines += ''
        $lines += "## $($result.TaskName)"
        $lines += ''
        $lines += '| Field | Value |'
        $lines += '|---|---|'
        $lines += "| Status | $($result.Status) |"
        $lines += "| Mode | $($result.Mode) |"
        $lines += "| Items Found | $($result.ItemsScanned) |"
        $lines += "| Items Modified | $($result.ItemsModified) |"
        $lines += "| Estimated Size | $(ConvertTo-ReadableSize -Bytes $result.EstimatedBytes) |"
        $lines += "| Recovered Size | $(ConvertTo-ReadableSize -Bytes $result.RecoveredBytes) |"

        if ($result.ActionsTaken.Count -gt 0) {
            $lines += ''
            $lines += 'Actions:'
            foreach ($item in $result.ActionsTaken) { $lines += "- $item" }
        }
        if ($result.Warnings.Count -gt 0) {
            $lines += ''
            $lines += 'Warnings:'
            foreach ($item in $result.Warnings) { $lines += "- $item" }
        }
        if ($result.Errors.Count -gt 0) {
            $lines += ''
            $lines += 'Errors:'
            foreach ($item in $result.Errors) { $lines += "- $item" }
        }
        if ($result.Recommendations.Count -gt 0) {
            $lines += ''
            $lines += 'Recommendations:'
            foreach ($item in $result.Recommendations) { $lines += "- $item" }
        }
    }

    $lines | Set-Content -Path $path -Encoding utf8
    return $path
}

Export-ModuleMember -Function New-WinCleanReport, ConvertTo-ReadableSize, Add-ReportSection, Write-MarkdownReport
