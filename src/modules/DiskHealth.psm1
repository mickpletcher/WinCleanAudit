function Get-DiskUsageSummary {
    [CmdletBinding()]
    param()

    $rows = @()
    try {
        $volumes = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter }
        foreach ($v in $volumes) {
            $used = [Int64]($v.Size - $v.SizeRemaining)
            $percentFree = if ($v.Size -gt 0) { [Math]::Round(($v.SizeRemaining / $v.Size) * 100, 2) } else { 0 }
            $warning = if ($percentFree -lt 15) { 'Low free space' } else { '' }
            $rows += [PSCustomObject]@{
                VolumeName  = $v.FileSystemLabel
                DriveLetter = $v.DriveLetter
                FileSystem  = $v.FileSystem
                Size        = [Int64]$v.Size
                FreeSpace   = [Int64]$v.SizeRemaining
                UsedSpace   = $used
                PercentFree = $percentFree
                Warning     = $warning
            }
        }
    }
    catch {
    }

    return $rows
}

function Get-DiskSmartHealth {
    [CmdletBinding()]
    param()

    $rows = @()
    try {
        $disks = Get-PhysicalDisk -ErrorAction SilentlyContinue
        foreach ($disk in $disks) {
            $rows += [PSCustomObject]@{
                FriendlyName      = $disk.FriendlyName
                MediaType         = $disk.MediaType
                OperationalStatus = ($disk.OperationalStatus -join ',')
                HealthStatus      = $disk.HealthStatus
                Size              = [Int64]$disk.Size
                Warning           = if ($disk.HealthStatus -ne 'Healthy') { 'Disk health is not healthy' } else { '' }
            }
        }
    }
    catch {
    }

    return $rows
}

function Invoke-DiskHealthReport {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt
    )

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Disk Health Report' -Module 'DiskHealth' -Mode 'DryRun'

    $usage = Get-DiskUsageSummary
    $smart = Get-DiskSmartHealth

    $result.ItemsScanned = @($usage).Count + @($smart).Count
    $result.Details = [PSCustomObject]@{
        Usage = $usage
        Smart = $smart
    }

    foreach ($u in $usage) {
        if ($u.Warning) { $result.Warnings += "$($u.DriveLetter): $($u.Warning)" }
    }
    foreach ($s in $smart) {
        if ($s.Warning) { $result.Warnings += "$($s.FriendlyName): $($s.Warning)" }
    }

    if ($result.Warnings.Count -gt 0) {
        $result.Status = 'Warning'
        $result.Recommendations += 'Review disk free space and health status.'
    }

    $result.ActionsTaken += 'Audit only. No disk changes were made.'
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

Export-ModuleMember -Function Get-DiskUsageSummary, Get-DiskSmartHealth, Invoke-DiskHealthReport
