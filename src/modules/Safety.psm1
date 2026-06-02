$script:ProtectedNames = @(
    'Desktop',
    'Documents',
    'Pictures',
    'Videos',
    'Music',
    'OneDrive',
    'Dropbox',
    'Google Drive'
)

$script:KnownFolderRegistryNames = @(
    'Desktop',
    'Personal',
    'My Pictures',
    'My Video',
    'My Music',
    '{754AC886-DF64-4CBA-86B5-F7FBF4FBCEF5}',
    '{F42EE2D3-909F-4907-8871-4C22FC0BF756}',
    '{0DDD015D-B06C-45D5-8C4C-F59713854639}',
    '{35286A68-3C57-41A1-BBB1-0EAE73D76C95}',
    '{A0C69A99-21C8-4671-8703-7934162FCF1D}'
)

function Get-WCARedirectedKnownFolderLocations {
    [CmdletBinding()]
    param()

    $registryPaths = @(
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'
    )

    $locations = foreach ($registryPath in $registryPaths) {
        try {
            $item = Get-ItemProperty -Path $registryPath -ErrorAction Stop
        }
        catch {
            continue
        }

        foreach ($name in $script:KnownFolderRegistryNames) {
            $property = $item.PSObject.Properties[$name]
            if ($property -and $property.Value) {
                [Environment]::ExpandEnvironmentVariables([string]$property.Value)
            }
        }
    }

    return @($locations | Where-Object { $_ } | Select-Object -Unique)
}

function Get-WCAProtectedLocations {
    [CmdletBinding()]
    param()

    $home = [Environment]::GetFolderPath('UserProfile')
    $profileLocations = foreach ($name in $script:ProtectedNames) {
        Join-Path $home $name
    }

    return @($profileLocations + (Get-WCARedirectedKnownFolderLocations)) |
        Where-Object { $_ } |
        Select-Object -Unique
}

function Normalize-WCAPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim('"'))
    return [System.IO.Path]::GetFullPath($expanded).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
}

function Test-WCAProtectedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $resolved = Normalize-WCAPath -Path $Path
    }
    catch {
        return $true
    }

    foreach ($protected in Get-WCAProtectedLocations) {
        try {
            $target = Normalize-WCAPath -Path $protected
            $isSamePath = [string]::Equals($resolved, $target, [System.StringComparison]::OrdinalIgnoreCase)
            $isChildPath = $resolved.StartsWith("$target$([IO.Path]::DirectorySeparatorChar)", [System.StringComparison]::OrdinalIgnoreCase) -or
                $resolved.StartsWith("$target$([IO.Path]::AltDirectorySeparatorChar)", [System.StringComparison]::OrdinalIgnoreCase)
            if ($isSamePath -or $isChildPath) {
                return $true
            }
        }
        catch {
            continue
        }
    }

    $parts = $resolved.Split([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    if ($parts -contains '.git' -or $parts -contains 'src' -or $parts -contains 'source') {
        return $true
    }
    if ($parts | Where-Object { $_ -eq 'Dropbox' -or $_ -eq 'Google Drive' -or $_ -eq 'OneDrive' -or $_ -like 'OneDrive - *' }) {
        return $true
    }

    return $false
}

function Confirm-WCAAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [switch]$Execute,
        [switch]$NoPrompt
    )

    if (-not $Execute) {
        return $false
    }

    if ($NoPrompt) {
        return $true
    }

    $answer = Read-Host "$Message [y/N]"
    return $answer -match '^(y|yes)$'
}

Export-ModuleMember -Function Confirm-WCAAction, Test-WCAProtectedPath, Get-WCAProtectedLocations, Get-WCARedirectedKnownFolderLocations, Normalize-WCAPath
