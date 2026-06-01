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

Export-ModuleMember -Function New-WCAResult
