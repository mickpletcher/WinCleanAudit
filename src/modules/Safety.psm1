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

function Get-WCAProtectedLocations {
    [CmdletBinding()]
    param()

    $home = [Environment]::GetFolderPath('UserProfile')
    $locations = foreach ($name in $script:ProtectedNames) {
        Join-Path $home $name
    }

    return $locations
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

Export-ModuleMember -Function Confirm-WCAAction, Test-WCAProtectedPath, Get-WCAProtectedLocations, Normalize-WCAPath
