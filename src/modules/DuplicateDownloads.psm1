function Get-DuplicateDownloads {
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path $env:USERPROFILE 'Downloads')
    )

    $groups = @()
    if (-not (Test-Path $Path)) { return $groups }

    $bySize = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue |
        Group-Object Length |
        Where-Object { $_.Count -gt 1 }

    foreach ($sizeGroup in $bySize) {
        $hashGroups = @{}
        foreach ($file in $sizeGroup.Group) {
            try {
                $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName -ErrorAction Stop).Hash
                if (-not $hashGroups.ContainsKey($hash)) { $hashGroups[$hash] = @() }
                $hashGroups[$hash] += $file
            }
            catch {
                continue
            }
        }

        foreach ($pair in $hashGroups.GetEnumerator()) {
            if ($pair.Value.Count -gt 1) {
                $groups += [PSCustomObject]@{
                    Hash  = $pair.Key
                    Size  = [Int64]$sizeGroup.Name
                    Files = @($pair.Value | ForEach-Object {
                        [PSCustomObject]@{ Path = $_.FullName; Size = [Int64]$_.Length; LastModified = $_.LastWriteTime }
                    })
                }
            }
        }
    }

    return $groups
}

function Invoke-DuplicateDownloadsReport {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt
    )

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Duplicate Downloads' -Module 'DuplicateDownloads' -Mode 'DryRun'

    $groups = Get-DuplicateDownloads
    $result.ItemsScanned = ($groups | ForEach-Object { $_.Files.Count } | Measure-Object -Sum).Sum
    $result.EstimatedBytes = [Int64](($groups | ForEach-Object { $_.Size * $_.Files.Count } | Measure-Object -Sum).Sum)
    $result.Details = $groups
    $result.Recommendations += 'Review duplicate groups manually before deleting files.'
    $result.ActionsTaken += 'Audit only. No files modified.'
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

Export-ModuleMember -Function Get-DuplicateDownloads, Invoke-DuplicateDownloadsReport
