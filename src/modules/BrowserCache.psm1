function Get-WCABrowserCachePaths {
    $local = $env:LOCALAPPDATA
    $roam = $env:APPDATA
    @(
        [PSCustomObject]@{ Browser = 'Chrome'; Path = Join-Path $local 'Google\Chrome\User Data\Default\Cache' },
        [PSCustomObject]@{ Browser = 'Edge'; Path = Join-Path $local 'Microsoft\Edge\User Data\Default\Cache' },
        [PSCustomObject]@{ Browser = 'Firefox'; Path = Join-Path $local 'Mozilla\Firefox\Profiles' },
        [PSCustomObject]@{ Browser = 'Brave'; Path = Join-Path $local 'BraveSoftware\Brave-Browser\User Data\Default\Cache' },
        [PSCustomObject]@{ Browser = 'Opera'; Path = Join-Path $roam 'Opera Software\Opera Stable\Cache' }
    )
}

function Get-BrowserCacheSummary {
    [CmdletBinding()]
    param()

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Browser Cache Cleanup' -Module 'BrowserCache' -Mode 'DryRun'

    $running = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'chrome|msedge|firefox|brave|opera' }
    if ($running) {
        $result.Warnings += 'One or more browsers are running and cache files may be locked.'
    }

    foreach ($entry in Get-WCABrowserCachePaths) {
        if (-not (Test-Path $entry.Path)) {
            $result.Warnings += ConvertTo-WCAFailureMessage -Message "Cache path not found for $($entry.Browser)" -Path $entry.Path
            continue
        }

        try {
            $bytes = 0
            $count = 0
            Get-ChildItem -Path $entry.Path -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                $count++
                $bytes += $_.Length
            }
            $result.ItemsScanned += $count
            $result.EstimatedBytes += $bytes
            $result.Details += [PSCustomObject]@{ Browser = $entry.Browser; Path = $entry.Path; Items = $count; Bytes = $bytes }
        }
        catch {
            $result.Warnings += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $entry.Path -Operation "Scan $($entry.Browser) cache"
        }
    }

    if ($result.Warnings.Count -gt 0) { $result.Status = 'Warning' }
    $result.ActionsTaken += 'Audit only. No browser cache files removed.'
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

function Clear-BrowserCache {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Execute,
        [switch]$NoPrompt
    )

    if ($NoPrompt -and -not $Execute) {
        throw '-NoPrompt can only be used with -Execute.'
    }

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Browser Cache Cleanup' -Module 'BrowserCache' -Mode 'Execute'

    if (-not $Execute) {
        $result.Status = 'Skipped'
        $result.ActionsTaken += 'Execute mode not supplied.'
        $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
        return $result
    }

    if (-not $NoPrompt) {
        $ok = Confirm-WCAAction -Message 'Delete browser cache files only?' -Execute -NoPrompt:$NoPrompt
        if (-not $ok) {
            $result.Status = 'Skipped'
            $result.ActionsTaken += 'User declined browser cache cleanup.'
            $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
            return $result
        }
    }

    $blockedNames = @('Bookmarks','Cookies','Login Data','History','Preferences')

    foreach ($entry in Get-WCABrowserCachePaths) {
        if (-not (Test-Path $entry.Path)) {
            $result.Warnings += ConvertTo-WCAFailureMessage -Message "Cache path not found for $($entry.Browser)" -Path $entry.Path
            continue
        }
        Get-ChildItem -Path $entry.Path -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $result.ItemsScanned++
            $result.EstimatedBytes += $_.Length
            if ($blockedNames -contains $_.Name) {
                $result.Warnings += "Protected browser file skipped: $($_.FullName)"
                Add-WCAExecutionLog -Result $result -Action 'Skip' -Status 'Skipped' -Target $_.FullName -Operation 'Remove browser cache file' -Reason 'Protected browser profile file' | Out-Null
                return
            }

            try {
                if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove browser cache file')) {
                    Add-WCAExecutionLog -Result $result -Action 'Delete' -Status 'Attempted' -Target $_.FullName -Operation 'Remove browser cache file' | Out-Null
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                    Add-WCAExecutionLog -Result $result -Action 'Delete' -Status 'Succeeded' -Target $_.FullName -Operation 'Remove browser cache file' | Out-Null
                    $result.ItemsModified++
                    $result.RecoveredBytes += $_.Length
                }
            }
            catch {
                Add-WCAExecutionLog -Result $result -Action 'Delete' -Status 'Failed' -Target $_.FullName -Operation 'Remove browser cache file' -Reason $_.Exception.Message | Out-Null
                $result.Warnings += ConvertTo-WCAFailureMessage -Message $_.Exception.Message -Path $_.FullName -Operation 'Remove browser cache file'
            }
        }
    }

    if ($result.Warnings.Count -gt 0) { $result.Status = 'Warning' }
    $result.ActionsTaken += "Removed $($result.ItemsModified) browser cache files."
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

function Invoke-BrowserCacheCleanup {
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

    if ($DryRun) { return Get-BrowserCacheSummary }
    return Clear-BrowserCache -Execute:$Execute -NoPrompt:$NoPrompt
}

Export-ModuleMember -Function Get-BrowserCacheSummary, Clear-BrowserCache, Invoke-BrowserCacheCleanup
