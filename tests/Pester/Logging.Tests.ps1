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

    It 'initializes with Event Log disabled' {
        $path = Join-Path $env:TEMP 'wca-tests-logging.log'
        Initialize-WCALogging -LogPath $path -Level INFO -EventLogEnabled $false
        Write-WCALog -Message 'test message' -Level INFO
        Close-WCALog

        Test-Path $path | Should -BeTrue
        Get-Content -Raw -Path $path | Should -Match 'test message'
    }
}
