BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\InstalledApps.psm1" -Force
}

Describe 'InstalledApps' {
    It 'imports and exposes functions' {
        Get-Command Get-InstalledApps -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-InstalledAppsInventory -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'is audit only' {
        $result = Invoke-InstalledAppsInventory
        $result.Mode | Should -Be 'DryRun'
        $result.ItemsModified | Should -Be 0
    }
}
