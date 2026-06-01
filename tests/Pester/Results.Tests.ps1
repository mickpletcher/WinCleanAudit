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
        $r.PSObject.Properties.Name | Should -Contain 'Duration'
    }
}
