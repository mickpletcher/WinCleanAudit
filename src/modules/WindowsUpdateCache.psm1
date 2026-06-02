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
                    Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Attempted' -Target $svc -Operation 'Stop service' | Out-Null
                    Stop-Service -Name $svc -Force -ErrorAction Stop
                    Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Succeeded' -Target $svc -Operation 'Stop service' | Out-Null
                }
                catch {
                    Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Failed' -Target $svc -Operation 'Stop service' -Reason $_.Exception.Message | Out-Null
                    $result.Warnings += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $svc -Operation 'Stop service'
                }
            }
            elseif ($service) {
                Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Skipped' -Target $svc -Operation 'Stop service' -Reason "Service status is $($service.Status)" | Out-Null
            }
            else {
                Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Skipped' -Target $svc -Operation 'Stop service' -Reason 'Service not found' | Out-Null
            }
        }

        Get-ChildItem -Path $path -Force -ErrorAction SilentlyContinue | ForEach-Object {
            $result.ItemsScanned++
            $size = if ($_.PSIsContainer) { 0 } else { $_.Length }
            $result.EstimatedBytes += $size
            try {
                if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove cache child item')) {
                    Add-WCAExecutionLog -Result $result -Action 'Delete' -Status 'Attempted' -Target $_.FullName -Operation 'Remove Windows Update cache item' | Out-Null
                    Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction Stop
                    Add-WCAExecutionLog -Result $result -Action 'Delete' -Status 'Succeeded' -Target $_.FullName -Operation 'Remove Windows Update cache item' | Out-Null
                    $result.ItemsModified++
                    $result.RecoveredBytes += $size
                }
            }
            catch {
                Add-WCAExecutionLog -Result $result -Action 'Delete' -Status 'Failed' -Target $_.FullName -Operation 'Remove Windows Update cache item' -Reason $_.Exception.Message | Out-Null
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
                Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Attempted' -Target $svc -Operation 'Start service' | Out-Null
                Start-Service -Name $svc -ErrorAction Stop
                Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Succeeded' -Target $svc -Operation 'Start service' | Out-Null

                $service = Get-Service -Name $svc -ErrorAction Stop
                if ($service.Status -eq 'Running') {
                    Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Validated' -Target $svc -Operation 'Validate service restart' -Reason 'Running' | Out-Null
                }
                else {
                    $message = "Service restart validation failed. Current status: $($service.Status)"
                    Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Failed' -Target $svc -Operation 'Validate service restart' -Reason $message | Out-Null
                    $result.Warnings += ConvertTo-WCAFailureMessage -Message $message -Path $svc -Operation 'Validate service restart'
                }
            }
            catch {
                $result.Warnings += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $svc -Operation 'Start service'
                Add-WCAExecutionLog -Result $result -Action 'Service' -Status 'Failed' -Target $svc -Operation 'Start service' -Reason $_.Exception.Message | Out-Null
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
