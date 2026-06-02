function Get-TempCleanupAudit {
    [CmdletBinding()]
    param()

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Temp Cleanup' -Module 'TempCleanup' -Mode 'DryRun'
    $locations = @($env:TEMP, 'C:\Windows\Temp')

    foreach ($location in $locations) {
        if (-not $location -or -not (Test-Path $location)) {
            $result.Warnings += ConvertTo-WCAFailureMessage -Message "Location not found: $location" -Path $location
            continue
        }

        try {
            Get-ChildItem -Path $location -Force -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                $result.ItemsScanned++
                $result.EstimatedBytes += $_.Length
                if ($_.LastWriteTime -lt (Get-Date).AddDays(-30)) {
                    $result.Details += [PSCustomObject]@{ Path = $_.FullName; AgeDays = [int]((Get-Date) - $_.LastWriteTime).TotalDays }
                }
            }
        }
        catch {
            $result.Warnings += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $location -Operation 'Scan temp location'
        }
    }

    $result.ActionsTaken += 'Audit only. No files deleted.'
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    if ($result.Warnings.Count -gt 0) { $result.Status = 'Warning' }
    return $result
}

function Invoke-TempCleanup {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt
    )

    if ($NoPrompt -and -not $Execute) {
        throw '-NoPrompt can only be used with -Execute.'
    }

    if (-not $DryRun -and -not $Execute) { $DryRun = $true }
    if ($DryRun) { return Get-TempCleanupAudit }

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Temp Cleanup' -Module 'TempCleanup' -Mode 'Execute'
    $locations = @($env:TEMP, 'C:\Windows\Temp')
    $safeExt = @('.tmp','.log','.etl','.dmp','.old','.bak')

    if (-not $NoPrompt) {
        $ok = Confirm-WCAAction -Message 'Delete approved temp files?' -Execute -NoPrompt:$NoPrompt
        if (-not $ok) {
            $result.Status = 'Skipped'
            $result.ActionsTaken += 'User declined cleanup.'
            $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
            return $result
        }
    }

    foreach ($location in $locations) {
        if (-not $location -or -not (Test-Path $location)) {
            $result.Warnings += ConvertTo-WCAFailureMessage -Message "Location not found: $location" -Path $location
            continue
        }

        Get-ChildItem -Path $location -File -Force -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $result.ItemsScanned++
            $result.EstimatedBytes += $_.Length

            if (Test-WCAProtectedPath -Path $_.FullName) {
                $result.Warnings += "Protected path skipped: $($_.FullName)"
                Add-WCAExecutionLog -Result $result -Action 'Skip' -Status 'Skipped' -Target $_.FullName -Operation 'Remove temp file' -Reason 'Protected path' | Out-Null
                return
            }
            if ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                $result.Warnings += "Symlink skipped: $($_.FullName)"
                Add-WCAExecutionLog -Result $result -Action 'Skip' -Status 'Skipped' -Target $_.FullName -Operation 'Remove temp file' -Reason 'Reparse point' | Out-Null
                return
            }
            if ($safeExt -notcontains $_.Extension.ToLowerInvariant()) {
                Add-WCAExecutionLog -Result $result -Action 'Skip' -Status 'Skipped' -Target $_.FullName -Operation 'Remove temp file' -Reason 'Extension not allowed' | Out-Null
                return
            }

            try {
                if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove temp file')) {
                    Add-WCAExecutionLog -Result $result -Action 'Delete' -Status 'Attempted' -Target $_.FullName -Operation 'Remove temp file' | Out-Null
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                    Add-WCAExecutionLog -Result $result -Action 'Delete' -Status 'Succeeded' -Target $_.FullName -Operation 'Remove temp file' | Out-Null
                    $result.ItemsModified++
                    $result.RecoveredBytes += $_.Length
                }
            }
            catch {
                Add-WCAExecutionLog -Result $result -Action 'Delete' -Status 'Failed' -Target $_.FullName -Operation 'Remove temp file' -Reason $_.Exception.Message | Out-Null
                $result.Warnings += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $_.FullName -Operation 'Remove temp file'
            }
        }
    }

    $result.ActionsTaken += "Removed $($result.ItemsModified) temp files."
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    if ($result.Warnings.Count -gt 0) { $result.Status = 'Warning' }
    return $result
}

Export-ModuleMember -Function Get-TempCleanupAudit, Invoke-TempCleanup
