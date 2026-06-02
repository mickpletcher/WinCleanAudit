$script:WcaLogFile = $null
$script:WcaLogLevel = 'INFO'
$script:WcaEventLogEnabled = $false
$script:WcaEventLogName = 'Application'
$script:WcaEventLogSource = 'WinCleanAudit'
$script:WcaEventIds = @{
    Info                = 1000
    Success             = 1001
    Warning             = 2000
    AccessDenied        = 2101
    LockedFile          = 2102
    MissingPath         = 2103
    ServiceControlError = 2104
    GeneralError        = 3000
}

function Get-WCAEventId {
    [CmdletBinding()]
    param(
        [ValidateSet('DEBUG','INFO','WARNING','ERROR','SUCCESS')]
        [string]$Level = 'INFO',
        [string]$FailureCategory = '',
        [string]$Message = ''
    )

    if ($FailureCategory -and $script:WcaEventIds.ContainsKey($FailureCategory)) {
        return $script:WcaEventIds[$FailureCategory]
    }
    if ($Message -match '^\[(AccessDenied|LockedFile|MissingPath|ServiceControlError|GeneralError)\]') {
        return $script:WcaEventIds[$matches[1]]
    }
    if ($Level -eq 'SUCCESS') {
        return $script:WcaEventIds.Success
    }
    if ($Level -eq 'WARNING') {
        return $script:WcaEventIds.Warning
    }
    if ($Level -eq 'ERROR') {
        return $script:WcaEventIds.GeneralError
    }

    return $script:WcaEventIds.Info
}

function Initialize-WCALogging {
    [CmdletBinding()]
    param(
        [string]$LogPath,
        [ValidateSet('DEBUG','INFO','WARNING','ERROR','SUCCESS')]
        [string]$Level = 'INFO',
        [bool]$EventLogEnabled = $false,
        [string]$EventLogName = 'Application',
        [string]$EventLogSource = 'WinCleanAudit'
    )

    $script:WcaLogLevel = $Level
    $script:WcaEventLogEnabled = $EventLogEnabled
    $script:WcaEventLogName = $EventLogName
    $script:WcaEventLogSource = $EventLogSource

    if ($script:WcaEventLogEnabled -and -not [System.Diagnostics.EventLog]::SourceExists($script:WcaEventLogSource)) {
        try {
            New-EventLog -LogName $script:WcaEventLogName -Source $script:WcaEventLogSource -ErrorAction Stop
        }
        catch {
            $script:WcaEventLogEnabled = $false
        }
    }

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
        [string]$Level = 'INFO',
        [ValidateSet('','AccessDenied','LockedFile','MissingPath','ServiceControlError','GeneralError')]
        [string]$FailureCategory = ''
    )

    $line = "$(Get-Date -Format s) [$Level] $Message"
    Write-Host $line
    if ($script:WcaLogFile) {
        $line | Out-File -FilePath $script:WcaLogFile -Encoding utf8 -Append
    }
    if ($script:WcaEventLogEnabled) {
        $entryType = switch ($Level) {
            'ERROR' { 'Error' }
            'WARNING' { 'Warning' }
            default { 'Information' }
        }
        try {
            $eventId = Get-WCAEventId -Level $Level -FailureCategory $FailureCategory -Message $Message
            Write-EventLog -LogName $script:WcaEventLogName -Source $script:WcaEventLogSource -EntryType $entryType -EventId $eventId -Message $Message -ErrorAction Stop
        }
        catch {
            $script:WcaEventLogEnabled = $false
        }
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

Export-ModuleMember -Function Initialize-WCALogging, Write-WCALog, Write-WCAError, Close-WCALog, Get-WCAEventId
