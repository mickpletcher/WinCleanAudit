function Get-RecycleBinSummary {
    [CmdletBinding()]
    param()

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Recycle Bin' -Module 'RecycleBin' -Mode 'DryRun'

    try {
        $items = Get-ChildItem -Path 'C:\$Recycle.Bin' -Recurse -Force -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $result.ItemsScanned++
            if (-not $item.PSIsContainer) {
                $result.EstimatedBytes += $item.Length
            }
        }
    }
    catch {
        $result.Status = 'Warning'
        $result.Errors += $_.Exception.Message
    }

    $result.ActionsTaken += 'Audit only. Recycle Bin not emptied.'
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

function Clear-WinCleanRecycleBin {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Execute,
        [switch]$NoPrompt
    )

    if ($NoPrompt -and -not $Execute) {
        throw '-NoPrompt can only be used with -Execute.'
    }

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Recycle Bin' -Module 'RecycleBin' -Mode 'Execute'

    if (-not $Execute) {
        $result.Status = 'Skipped'
        $result.ActionsTaken += 'Execute mode not supplied. No changes made.'
        $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
        return $result
    }

    if (-not $NoPrompt) {
        $ok = Confirm-WCAAction -Message 'Empty Recycle Bin?' -Execute -NoPrompt:$NoPrompt
        if (-not $ok) {
            $result.Status = 'Skipped'
            $result.ActionsTaken += 'User declined recycle bin cleanup.'
            $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
            return $result
        }
    }

    try {
        if ($PSCmdlet.ShouldProcess('Recycle Bin', 'Clear-RecycleBin')) {
            Clear-RecycleBin -Force -ErrorAction Stop
            $result.ActionsTaken += 'Recycle Bin emptied.'
            $result.ItemsModified = 1
        }
    }
    catch {
        $result.Status = 'Warning'
        $result.Errors += $_.Exception.Message
    }

    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

function Invoke-RecycleBinCleanup {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt
    )

    if ($NoPrompt -and -not $Execute) {
        throw '-NoPrompt can only be used with -Execute.'
    }
    if (-not $DryRun -and -not $Execute) { $DryRun = $true }

    if ($DryRun) {
        return Get-RecycleBinSummary
    }

    return Clear-WinCleanRecycleBin -Execute:$Execute -NoPrompt:$NoPrompt
}

Export-ModuleMember -Function Get-RecycleBinSummary, Clear-WinCleanRecycleBin, Invoke-RecycleBinCleanup
