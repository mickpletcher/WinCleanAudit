BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Logging.psm1" -Force
}

Describe 'Logging' {
    It 'imports and exposes functions' {
        Get-Command Initialize-WCALogging -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-WCALog -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-WCAError -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Close-WCALog -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
