function Test-WCAIsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-WindowsUpdateCacheInfo {
    [CmdletBinding()]
    param()

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Windows Update Cache' -Module 'WindowsUpdateCache' -Mode 'DryRun'
    $path = 'C:\Windows\SoftwareDistribution\Download'

    if (-not (Test-Path $path)) {
        $result.Status = 'Skipped'
        $result.Warnings += ConvertTo-WCAFailureMessage -Message 'Windows Update cache folder not found.' -Path $path
        $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
        return $result
    }

    try {
        Get-ChildItem -Path $path -Force -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $result.ItemsScanned++
            $result.EstimatedBytes += $_.Length
        }
    }
    catch {
        $result.Status = 'Warning'
        $result.Errors += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $path -Operation 'Scan Windows Update cache'
    }

    $result.ActionsTaken += 'Audit only. No cache files removed.'
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

function Clear-WindowsUpdateCache {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Execute,
        [switch]$NoPrompt
    )

    if (-not $Execute) {
        throw 'Clear-WindowsUpdateCache requires -Execute.'
    }
    if ($NoPrompt -and -not $Execute) {
        throw '-NoPrompt can only be used with -Execute.'
    }
    if (-not (Test-WCAIsAdministrator)) {
        throw 'Administrator rights are required for Windows Update cache cleanup.'
    }

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Windows Update Cache' -Module 'WindowsUpdateCache' -Mode 'Execute'
    $path = 'C:\Windows\SoftwareDistribution\Download'
    $services = @('wuauserv','bits','cryptsvc')
    $runningBefore = @()

    if (-not $NoPrompt) {
        $ok = Confirm-WCAAction -Message 'Delete Windows Update cache child items?' -Execute -NoPrompt:$NoPrompt
        if (-not $ok) {
            $result.Status = 'Skipped'
            $result.ActionsTaken += 'User declined cleanup.'
            $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
            return $result
        }
    }

    try {
        foreach ($svc in $services) {
            $service = Get-Service -Name $svc -ErrorAction SilentlyContinue
            if ($service -and $service.Status -eq 'Running') {
                $runningBefore += $svc
                try {
                    Stop-Service -Name $svc -Force -ErrorAction Stop
                }
                catch {
                    $result.Warnings += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $svc -Operation 'Stop service'
                }
            }
        }

        Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $result.ItemsScanned++
            $size = if ($_.PSIsContainer) { 0 } else { $_.Length }
            $result.EstimatedBytes += $size
            try {
                if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove cache child item')) {
                    Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
                    $result.ItemsModified++
                    $result.RecoveredBytes += $size
                }
            }
            catch {
                $result.Warnings += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $_.FullName -Operation 'Remove Windows Update cache item'
            }
        }
    }
    catch {
        $result.Status = 'Error'
        $result.Errors += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $path -Operation 'Clear Windows Update cache'
    }
    finally {
        foreach ($svc in $runningBefore) {
            try {
                Start-Service -Name $svc -ErrorAction Stop
            }
            catch {
                $result.Warnings += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $svc -Operation 'Start service'
            }
        }
    }

    $result.ActionsTaken += "Removed $($result.ItemsModified) cache child items."
    if ($result.Warnings.Count -gt 0 -and $result.Status -eq 'Success') { $result.Status = 'Warning' }
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

function Invoke-WindowsUpdateCacheTask {
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
    if ($DryRun) { return Get-WindowsUpdateCacheInfo }

    return Clear-WindowsUpdateCache -Execute:$Execute -NoPrompt:$NoPrompt
}

Export-ModuleMember -Function Get-WindowsUpdateCacheInfo, Clear-WindowsUpdateCache, Invoke-WindowsUpdateCacheTask
