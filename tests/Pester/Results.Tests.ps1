BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
}

Describe 'Results' {
    It 'creates common contract object' {
        $r = New-WCAResult -TaskName 'Test' -Module 'Unit' -Mode 'DryRun'
        $r.PSObject.Properties.Name | Should -Contain 'TaskName'
        $r.PSObject.Properties.Name | Should -Contain 'Module'
        $r.PSObject.Properties.Name | Should -Contain 'Status'
        $r.PSObject.Properties.Name | Should -Contain 'Mode'
        $r.PSObject.Properties.Name | Should -Contain 'ItemsScanned'
        $r.PSObject.Properties.Name | Should -Contain 'ItemsModified'
        $r.PSObject.Properties.Name | Should -Contain 'EstimatedBytes'
        $r.PSObject.Properties.Name | Should -Contain 'RecoveredBytes'
        $r.PSObject.Properties.Name | Should -Contain 'ActionsTaken'
        $r.PSObject.Properties.Name | Should -Contain 'Warnings'
        $r.PSObject.Properties.Name | Should -Contain 'Errors'
        $r.PSObject.Properties.Name | Should -Contain 'Recommendations'
        $r.PSObject.Properties.Name | Should -Contain 'Details'
        $r.PSObject.Properties.Name | Should -Contain 'ExecutionLog'
        $r.PSObject.Properties.Name | Should -Contain 'Duration'
    }

    It 'adds structured execution log entries' {
        $r = New-WCAResult -TaskName 'Test' -Module 'Unit' -Mode 'Execute'

        Add-WCAExecutionLog -Result $r -Action 'Delete' -Status 'Attempted' -Target 'C:\Temp\a.tmp' -Operation 'Remove temp file' | Out-Null

        $r.ExecutionLog.Count | Should -Be 1
        $r.ExecutionLog[0].Action | Should -Be 'Delete'
        $r.ExecutionLog[0].Status | Should -Be 'Attempted'
        $r.ExecutionLog[0].Target | Should -Be 'C:\Temp\a.tmp'
    }

    It 'classifies access denied failures' {
        ConvertTo-WCAFailureMessage -Message 'Access to the path is denied.' -Path 'C:\Windows\Temp\a.tmp' |
            Should -Match '^\[AccessDenied\]'
    }

    It 'classifies locked file failures' {
        ConvertTo-WCAFailureMessage -Message 'The process cannot access the file because it is being used by another process.' -Path 'C:\Temp\a.tmp' |
            Should -Match '^\[LockedFile\]'
    }

    It 'classifies missing path failures' {
        ConvertTo-WCAFailureMessage -Message 'Cannot find path C:\Missing because it does not exist.' -Path 'C:\Missing' |
            Should -Match '^\[MissingPath\]'
    }

    It 'classifies service control failures' {
        ConvertTo-WCAFailureMessage -Message 'Cannot stop service wuauserv.' -Path 'wuauserv' -Operation 'Stop service' |
            Should -Match '^\[ServiceControlError\]'
    }
}
