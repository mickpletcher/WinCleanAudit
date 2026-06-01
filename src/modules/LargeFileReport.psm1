function Get-LargeFiles {
    [CmdletBinding()]
    param(
        [Int64]$MinimumBytes = 536870912,
        [string[]]$Paths = @((Join-Path $env:USERPROFILE 'Downloads'))
    )

    $results = @()
    foreach ($path in $Paths) {
        if (-not (Test-Path $path)) { continue }
        if (Test-WCAProtectedPath -Path $path) { continue }

        try {
            Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Length -ge $MinimumBytes } | ForEach-Object {
                $results += [PSCustomObject]@{
                    Path         = $_.FullName
                    SizeBytes    = [Int64]$_.Length
                    ReadableSize = ConvertTo-ReadableSize -Bytes $_.Length
                    LastModified = $_.LastWriteTime
                    Extension    = $_.Extension
                    ParentFolder = $_.DirectoryName
                }
            }
        }
        catch {
        }
    }

    return $results
}

function Invoke-LargeFileReport {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt,
        [int]$MinimumSizeMB = 500
    )

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Large File Report' -Module 'LargeFileReport' -Mode 'DryRun'
    $minimum = [Int64]$MinimumSizeMB * 1MB
    $files = Get-LargeFiles -MinimumBytes $minimum

    $result.ItemsScanned = $files.Count
    $result.EstimatedBytes = [Int64]($files | Measure-Object -Property SizeBytes -Sum).Sum
    $result.Details = $files
    $result.ActionsTaken += 'Audit only. No files modified.'
    $result.Recommendations += 'Manually review large files before deleting anything.'
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

Export-ModuleMember -Function Get-LargeFiles, Invoke-LargeFileReport
