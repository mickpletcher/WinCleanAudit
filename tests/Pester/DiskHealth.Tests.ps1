BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\DiskHealth.psm1" -Force
}

Describe 'DiskHealth' {
    It 'imports and exposes functions' {
        Get-Command Get-DiskUsageSummary -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-DiskSmartHealth -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-DiskHealthReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'is read only' {
        $result = Invoke-DiskHealthReport
        $result.Mode | Should -Be 'DryRun'
        $result.ItemsModified | Should -Be 0
    }
}
