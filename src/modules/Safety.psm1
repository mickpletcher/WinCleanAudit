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

function Test-WCAProtectedPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $resolved = [System.IO.Path]::GetFullPath($Path)
    }
    catch {
        return $true
    }

    foreach ($protected in Get-WCAProtectedLocations) {
        try {
            $target = [System.IO.Path]::GetFullPath($protected)
            if ($resolved.StartsWith($target, [System.StringComparison]::OrdinalIgnoreCase)) {
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

Export-ModuleMember -Function Confirm-WCAAction, Test-WCAProtectedPath, Get-WCAProtectedLocations
