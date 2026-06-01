BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\StartupInventory.psm1" -Force
}

Describe 'StartupInventory' {
    It 'imports and exposes functions' {
        Get-Command Get-StartupFolderItems -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-RegistryStartupItems -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-StartupScheduledTasks -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-StartupInventory -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'is audit only' {
        $result = Invoke-StartupInventory -DryRun
        $result.Mode | Should -Be 'DryRun'
        $result.ItemsModified | Should -Be 0
    }
}
