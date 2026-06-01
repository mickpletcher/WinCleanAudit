function Get-StartupFolderItems {
    [CmdletBinding()]
    param()

    $results = @()
    $paths = @(
        [Environment]::GetFolderPath('Startup'),
        "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp"
    )

    foreach ($path in $paths) {
        if (-not (Test-Path $path)) {
            $results += [PSCustomObject]@{ Name = 'N/A'; Path = $path; Source = 'StartupFolder'; Command = ''; Publisher = ''; Enabled = $false; Warning = 'Path missing'; Recommendation = 'Review startup path.' }
            continue
        }

        Get-ChildItem -Path $path -File -ErrorAction SilentlyContinue | ForEach-Object {
            $results += [PSCustomObject]@{ Name = $_.Name; Path = $_.FullName; Source = 'StartupFolder'; Command = $_.FullName; Publisher = ''; Enabled = $true; Warning = ''; Recommendation = '' }
        }
    }

    return $results
}

function Get-RegistryStartupItems {
    [CmdletBinding()]
    param()

    $keys = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
    )

    $results = @()
    foreach ($key in $keys) {
        try {
            if (-not (Test-Path $key)) { continue }
            $item = Get-ItemProperty -Path $key -ErrorAction Stop
            foreach ($prop in $item.PSObject.Properties) {
                if ($prop.Name -in @('PSPath','PSParentPath','PSChildName','PSProvider','PSDrive')) { continue }
                $results += [PSCustomObject]@{ Name = $prop.Name; Path = ''; Source = $key; Command = [string]$prop.Value; Publisher = ''; Enabled = $true; Warning = ''; Recommendation = '' }
            }
        }
        catch {
            $results += [PSCustomObject]@{ Name = 'RegistryError'; Path = $key; Source = 'Registry'; Command = ''; Publisher = ''; Enabled = $false; Warning = $_.Exception.Message; Recommendation = 'Review registry permissions.' }
        }
    }

    return $results
}

function Get-StartupScheduledTasks {
    [CmdletBinding()]
    param()

    $results = @()
    try {
        $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
            $_.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' }
        }

        foreach ($task in $tasks) {
            $action = ($task.Actions | Select-Object -First 1).Execute
            $results += [PSCustomObject]@{ Name = $task.TaskName; Path = $task.TaskPath; Source = 'ScheduledTask'; Command = $action; Publisher = ''; Enabled = ($task.State -ne 'Disabled'); Warning = ''; Recommendation = '' }
        }
    }
    catch {
        $results += [PSCustomObject]@{ Name = 'TaskError'; Path = ''; Source = 'ScheduledTask'; Command = ''; Publisher = ''; Enabled = $false; Warning = $_.Exception.Message; Recommendation = 'Review task access.' }
    }

    return $results
}

function Invoke-StartupInventory {
    [CmdletBinding()]
    param(
        [switch]$DryRun,
        [switch]$Execute,
        [switch]$NoPrompt
    )

    $start = Get-Date
    $result = New-WCAResult -TaskName 'Startup Inventory' -Module 'StartupInventory' -Mode 'DryRun'

    $items = @()
    $items += Get-StartupFolderItems
    $items += Get-RegistryStartupItems
    $items += Get-StartupScheduledTasks

    $result.ItemsScanned = $items.Count
    $result.Details = $items
    $result.Recommendations += @($items | Where-Object { $_.Warning -or $_.Recommendation } | ForEach-Object { "Review startup item: $($_.Name)" })
    $result.ActionsTaken += 'Audit only. No startup entries were changed.'
    if (($items | Where-Object { $_.Warning }).Count -gt 0) { $result.Status = 'Warning' }
    $result.Duration = [Math]::Round(((Get-Date) - $start).TotalSeconds, 3)

    return $result
}

Export-ModuleMember -Function Get-StartupFolderItems, Get-RegistryStartupItems, Get-StartupScheduledTasks, Invoke-StartupInventory
