function New-WCAResult {
    [CmdletBinding()]
    param(
        [string]$TaskName = '',
        [string]$Module = '',
        [ValidateSet('Success','Warning','Error','Skipped')]
        [string]$Status = 'Success',
        [ValidateSet('DryRun','Execute')]
        [string]$Mode = 'DryRun'
    )

    [PSCustomObject]@{
        TaskName        = $TaskName
        Module          = $Module
        Status          = $Status
        Mode            = $Mode
        ItemsScanned    = 0
        ItemsModified   = 0
        EstimatedBytes  = [Int64]0
        RecoveredBytes  = [Int64]0
        ActionsTaken    = @()
        Warnings        = @()
        Errors          = @()
        Recommendations = @()
        Details         = @()
        Duration        = 0
    }
}

function ConvertTo-WCAFailureMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Message,
        [string]$Path = '',
        [string]$Operation = ''
    )

    $text = $Message
    $category = 'GeneralError'

    if ($Operation -match '(?i)service' -or $text -match '(?i)service|Stop-Service|Start-Service|wuauserv|bits|cryptsvc') {
        $category = 'ServiceControlError'
    }
    elseif ($text -match '(?i)access.*denied|permission denied|unauthorized|privilege|administrator rights') {
        $category = 'AccessDenied'
    }
    elseif ($text -match '(?i)being used by another process|used by another process|cannot access the file|locked') {
        $category = 'LockedFile'
    }
    elseif ($text -match '(?i)path.*not found|cannot find path|could not find.*path|does not exist|not found') {
        $category = 'MissingPath'
    }

    $target = if ($Path) { " $Path" } else { '' }
    $operationText = if ($Operation) { " $Operation" } else { '' }
    return "[$category]$operationText$target`: $text"
}

Export-ModuleMember -Function New-WCAResult, ConvertTo-WCAFailureMessage
