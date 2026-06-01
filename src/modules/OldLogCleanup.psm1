function Get-OldLogSummary {
    [CmdletBinding()]
    param(
        [int]$AgeDays = 30
    )

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Old Log Cleanup' -Module 'OldLogCleanup' -Mode 'DryRun'
    $paths = @('C:\Windows\Logs','C:\Windows\Temp','C:\ProgramData\Microsoft\Windows\WER')
    $ext = @('.log','.etl','.tmp','.dmp','.trace','.bak')
    $cutoff = (Get-Date).AddDays(-$AgeDays)

    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            $result.Warnings += "Path missing: $path"
            continue
        }

        try {
            Get-ChildItem -Path $path -File -Recurse -ErrorAction SilentlyContinue | Where-Object {
                $ext -contains $_.Extension.ToLowerInvariant() -and $_.LastWriteTime -lt $cutoff
            } | ForEach-Object {
                $result.ItemsScanned++
                $result.EstimatedBytes += $_.Length
                $result.Details += [PSCustomObject]@{ Path = $_.FullName; LastWriteTime = $_.LastWriteTime }
            }
        }
        catch {
            $result.Warnings += "Scan warning for ${path}: $($_.Exception.Message)"
        }
    }

    $result.ActionsTaken += 'Audit only. No files removed.'
    if ($result.Warnings.Count -gt 0) { $result.Status = 'Warning' }
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

function Clear-OldLogs {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Execute,
        [switch]$NoPrompt,
        [int]$AgeDays = 30
    )

    if ($NoPrompt -and -not $Execute) {
        throw '-NoPrompt can only be used with -Execute.'
    }

    if (-not $Execute) {
        return Get-OldLogSummary -AgeDays $AgeDays
    }

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Old Log Cleanup' -Module 'OldLogCleanup' -Mode 'Execute'
    $candidate = Get-OldLogSummary -AgeDays $AgeDays

    if (-not $NoPrompt) {
        $ok = Confirm-WCAAction -Message 'Delete approved old log files?' -Execute -NoPrompt:$NoPrompt
        if (-not $ok) {
            $result.Status = 'Skipped'
            $result.ActionsTaken += 'User declined old log cleanup.'
            $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
            return $result
        }
    }

    foreach ($entry in $candidate.Details) {
        if (Test-WCAProtectedPath -Path $entry.Path) {
            $result.Warnings += "Protected path skipped: $($entry.Path)"
            continue
        }
        try {
            $item = Get-Item -LiteralPath $entry.Path -ErrorAction Stop
            $result.ItemsScanned++
            $result.EstimatedBytes += $item.Length
            if ($PSCmdlet.ShouldProcess($entry.Path, 'Remove old log file')) {
                Remove-Item -LiteralPath $entry.Path -Force -ErrorAction Stop
                $result.ItemsModified++
                $result.RecoveredBytes += $item.Length
            }
        }
        catch {
            $result.Warnings += "Skip file: $($entry.Path)"
        }
    }

    if ($result.Warnings.Count -gt 0) { $result.Status = 'Warning' }
    $result.ActionsTaken += "Removed $($result.ItemsModified) old log files."
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

function Invoke-OldLogCleanup {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt,
        [int]$AgeDays = 30
    )

    if ($NoPrompt -and -not $Execute) {
        throw '-NoPrompt can only be used with -Execute.'
    }
    if (-not $DryRun -and -not $Execute) { $DryRun = $true }
    if ($DryRun) {
        return Get-OldLogSummary -AgeDays $AgeDays
    }

    return Clear-OldLogs -Execute:$Execute -NoPrompt:$NoPrompt -AgeDays $AgeDays
}

Export-ModuleMember -Function Get-OldLogSummary, Clear-OldLogs, Invoke-OldLogCleanup
