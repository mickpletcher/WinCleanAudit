$script:WcaLogFile = $null
$script:WcaLogLevel = 'INFO'

function Initialize-WCALogging {
    [CmdletBinding()]
    param(
        [string]$LogPath,
        [ValidateSet('DEBUG','INFO','WARNING','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    $script:WcaLogLevel = $Level
    if (-not $LogPath) {
        return
    }

    $folder = Split-Path -Path $LogPath -Parent
    if ($folder -and -not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }

    $script:WcaLogFile = $LogPath
    "$(Get-Date -Format s) [INFO] Logging initialized" | Out-File -FilePath $script:WcaLogFile -Encoding utf8 -Append
}

function Write-WCALog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('DEBUG','INFO','WARNING','ERROR','SUCCESS')]
        [string]$Level = 'INFO'
    )

    $line = "$(Get-Date -Format s) [$Level] $Message"
    Write-Host $line
    if ($script:WcaLogFile) {
        $line | Out-File -FilePath $script:WcaLogFile -Encoding utf8 -Append
    }
}

function Write-WCAError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [System.Exception]$Exception
    )

    $full = if ($Exception) { "$Message :: $($Exception.Message)" } else { $Message }
    Write-WCALog -Message $full -Level 'ERROR'
}

function Close-WCALog {
    [CmdletBinding()]
    param()

    if ($script:WcaLogFile) {
        "$(Get-Date -Format s) [INFO] Logging closed" | Out-File -FilePath $script:WcaLogFile -Encoding utf8 -Append
    }
}

Export-ModuleMember -Function Initialize-WCALogging, Write-WCALog, Write-WCAError, Close-WCALog
