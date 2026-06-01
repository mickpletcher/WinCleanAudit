function Get-InstalledApps {
    [CmdletBinding()]
    param()

    $paths = @(
        @{ Path = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'; Scope = 'Machine' },
        @{ Path = 'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'; Scope = 'Machine32' },
        @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'; Scope = 'User' }
    )

    $apps = @()
    foreach ($entry in $paths) {
        try {
            Get-ItemProperty -Path $entry.Path -ErrorAction SilentlyContinue | ForEach-Object {
                if (-not $_.DisplayName) { return }
                $apps += [PSCustomObject]@{
                    Name            = $_.DisplayName
                    Version         = $_.DisplayVersion
                    Publisher       = $_.Publisher
                    InstallDate     = $_.InstallDate
                    UninstallString = $_.UninstallString
                    InstallLocation = $_.InstallLocation
                    Scope           = $entry.Scope
                }
            }
        }
        catch {
            continue
        }
    }

    return $apps
}

function Invoke-InstalledAppsInventory {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt
    )

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Installed Apps Inventory' -Module 'InstalledApps' -Mode 'DryRun'
    $apps = Get-InstalledApps

    $result.ItemsScanned = $apps.Count
    $result.Details = $apps
    $missingPublisher = @($apps | Where-Object { -not $_.Publisher }).Count
    if ($missingPublisher -gt 0) {
        $result.Warnings += "$missingPublisher app entries are missing a publisher value."
        $result.Recommendations += 'Review unknown or missing publisher entries.'
        $result.Status = 'Warning'
    }

    $result.ActionsTaken += 'Audit only. No applications changed.'
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)
    return $result
}

Export-ModuleMember -Function Get-InstalledApps, Invoke-InstalledAppsInventory
