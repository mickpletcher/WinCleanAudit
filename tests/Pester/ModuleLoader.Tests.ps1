BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\ModuleLoader.psm1" -Force
}

Describe 'ModuleLoader' {
    It 'imports and exposes functions' {
        Get-Command Import-WCAModules -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-WCAAvailableModules -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
