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

function ConvertTo-HtmlText {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ''
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
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
        [string]$OutputFolder = 'reports',
        [string]$Timestamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
    )

    if (-not (Test-Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    $fileName = 'cleanup-report-{0}.md' -f $Timestamp
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

function Write-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Report,
        [string]$OutputFolder = 'reports',
        [string]$Timestamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
    )

    if (-not (Test-Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    $fileName = 'cleanup-report-{0}.html' -f $Timestamp
    $path = Join-Path $OutputFolder $fileName

    $summaryRows = foreach ($result in $Report.Results) {
        '<tr><td>{0}</td><td>{1}</td><td>{2}</td><td>{3}</td><td>{4}</td><td>{5}</td></tr>' -f
            (ConvertTo-HtmlText $result.Module),
            (ConvertTo-HtmlText $result.Status),
            (ConvertTo-HtmlText $result.ItemsScanned),
            (ConvertTo-HtmlText $result.ItemsModified),
            (ConvertTo-HtmlText (ConvertTo-ReadableSize -Bytes $result.EstimatedBytes)),
            (ConvertTo-HtmlText (ConvertTo-ReadableSize -Bytes $result.RecoveredBytes))
    }

    $moduleSections = foreach ($result in $Report.Results) {
        $listBlocks = @()
        foreach ($name in @('ActionsTaken','Warnings','Errors','Recommendations')) {
            if ($result.$name.Count -gt 0) {
                $items = foreach ($item in $result.$name) {
                    '<li>{0}</li>' -f (ConvertTo-HtmlText $item)
                }
                $heading = $name -replace '([a-z])([A-Z])', '$1 $2'
                $listBlocks += '<h3>{0}</h3><ul>{1}</ul>' -f $heading, ($items -join '')
            }
        }

        @"
<section>
  <h2>$(ConvertTo-HtmlText $result.TaskName)</h2>
  <table>
    <tbody>
      <tr><th>Status</th><td>$(ConvertTo-HtmlText $result.Status)</td></tr>
      <tr><th>Mode</th><td>$(ConvertTo-HtmlText $result.Mode)</td></tr>
      <tr><th>Items Found</th><td>$(ConvertTo-HtmlText $result.ItemsScanned)</td></tr>
      <tr><th>Items Modified</th><td>$(ConvertTo-HtmlText $result.ItemsModified)</td></tr>
      <tr><th>Estimated Size</th><td>$(ConvertTo-HtmlText (ConvertTo-ReadableSize -Bytes $result.EstimatedBytes))</td></tr>
      <tr><th>Recovered Size</th><td>$(ConvertTo-HtmlText (ConvertTo-ReadableSize -Bytes $result.RecoveredBytes))</td></tr>
    </tbody>
  </table>
  $($listBlocks -join "`n  ")
</section>
"@
    }

    $html = @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>WinCleanAudit Report</title>
  <style>
    body { font-family: "Segoe UI", Arial, sans-serif; margin: 2rem; color: #1f2937; background: #f8fafc; }
    main { max-width: 1100px; margin: 0 auto; }
    h1, h2, h3 { color: #111827; }
    table { width: 100%; border-collapse: collapse; margin: 1rem 0 1.5rem; background: #fff; }
    th, td { border: 1px solid #d1d5db; padding: .6rem .75rem; text-align: left; vertical-align: top; }
    th { background: #e5e7eb; }
    section { margin-top: 2rem; }
    ul { background: #fff; border: 1px solid #d1d5db; padding: 1rem 1rem 1rem 2rem; }
  </style>
</head>
<body>
<main>
  <h1>WinCleanAudit Report</h1>
  <table>
    <tbody>
      <tr><th>Computer</th><td>$(ConvertTo-HtmlText $Report.ComputerName)</td></tr>
      <tr><th>User</th><td>$(ConvertTo-HtmlText $Report.UserName)</td></tr>
      <tr><th>Date</th><td>$(ConvertTo-HtmlText $Report.DateTime)</td></tr>
      <tr><th>PowerShell</th><td>$(ConvertTo-HtmlText $Report.PowerShellVersion)</td></tr>
      <tr><th>Mode</th><td>$(ConvertTo-HtmlText $Report.Mode)</td></tr>
    </tbody>
  </table>
  <h2>Summary</h2>
  <table>
    <thead>
      <tr><th>Module</th><th>Status</th><th>Items Scanned</th><th>Items Modified</th><th>Estimated</th><th>Recovered</th></tr>
    </thead>
    <tbody>
      $($summaryRows -join "`n      ")
    </tbody>
  </table>
  $($moduleSections -join "`n  ")
</main>
</body>
</html>
"@

    $html | Set-Content -Path $path -Encoding utf8
    return $path
}

function Write-JsonReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Report,
        [string]$OutputFolder = 'reports',
        [string]$Timestamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
    )

    if (-not (Test-Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    $fileName = 'cleanup-report-{0}.json' -f $Timestamp
    $path = Join-Path $OutputFolder $fileName

    $Report | ConvertTo-Json -Depth 8 | Set-Content -Path $path -Encoding utf8
    return $path
}

function Write-CsvReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Report,
        [string]$OutputFolder = 'reports',
        [string]$Timestamp = (Get-Date -Format 'yyyyMMdd-HHmmss')
    )

    if (-not (Test-Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    $fileName = 'cleanup-report-{0}.csv' -f $Timestamp
    $path = Join-Path $OutputFolder $fileName

    $rows = foreach ($result in $Report.Results) {
        [PSCustomObject]@{
            ComputerName      = $Report.ComputerName
            UserName          = $Report.UserName
            DateTime          = $Report.DateTime
            Mode              = $Report.Mode
            TaskName          = $result.TaskName
            Module            = $result.Module
            Status            = $result.Status
            ItemsScanned      = $result.ItemsScanned
            ItemsModified     = $result.ItemsModified
            EstimatedBytes    = $result.EstimatedBytes
            EstimatedReadable = ConvertTo-ReadableSize -Bytes $result.EstimatedBytes
            RecoveredBytes    = $result.RecoveredBytes
            RecoveredReadable = ConvertTo-ReadableSize -Bytes $result.RecoveredBytes
            ActionsTaken      = @($result.ActionsTaken) -join '; '
            Warnings          = @($result.Warnings) -join '; '
            Errors            = @($result.Errors) -join '; '
            Recommendations   = @($result.Recommendations) -join '; '
            Duration          = $result.Duration
        }
    }

    @($rows) | Export-Csv -Path $path -NoTypeInformation -Encoding utf8
    return $path
}

Export-ModuleMember -Function New-WinCleanReport, ConvertTo-ReadableSize, Add-ReportSection, Write-MarkdownReport, Write-HtmlReport, Write-JsonReport, Write-CsvReport
