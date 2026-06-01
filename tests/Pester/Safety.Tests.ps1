BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Safety.psm1" -Force
}

Describe 'Safety' {
    It 'imports and exposes functions' {
        Get-Command Confirm-WCAAction -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-WCAProtectedPath -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-WCAProtectedLocations -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'returns protected locations' {
        @(Get-WCAProtectedLocations).Count | Should -BeGreaterThan 0
    }
}
