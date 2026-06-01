BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Configuration.psm1" -Force
}

Describe 'Configuration' {
    It 'imports and exposes functions' {
        Get-Command Get-WCAConfiguration -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-WCAConfiguration -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'loads module entry points from configuration' {
        $config = Get-WCAConfiguration

        $config.modules.entry_points.TempCleanup | Should -Be 'Invoke-TempCleanup'
        $config.modules.entry_points.WindowsUpdateCache | Should -Be 'Invoke-WindowsUpdateCacheTask'
    }
}
