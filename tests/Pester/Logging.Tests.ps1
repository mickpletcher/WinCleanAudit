BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Logging.psm1" -Force
}

Describe 'Logging' {
    It 'imports and exposes functions' {
        Get-Command Initialize-WCALogging -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-WCALog -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-WCAError -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Close-WCALog -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-WCAEventId -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'initializes with Event Log disabled' {
        $path = Join-Path $env:TEMP 'wca-tests-logging.log'
        Initialize-WCALogging -LogPath $path -Level INFO -EventLogEnabled $false
        Write-WCALog -Message 'test message' -Level INFO
        Close-WCALog

        Test-Path $path | Should -BeTrue
        Get-Content -Raw -Path $path | Should -Match 'test message'
    }

    It 'maps failure categories to event IDs' {
        Get-WCAEventId -Level ERROR -FailureCategory AccessDenied | Should -Be 2101
        Get-WCAEventId -Level WARNING -FailureCategory LockedFile | Should -Be 2102
        Get-WCAEventId -Level WARNING -FailureCategory MissingPath | Should -Be 2103
        Get-WCAEventId -Level ERROR -FailureCategory ServiceControlError | Should -Be 2104
    }

    It 'infers event IDs from classified messages' {
        Get-WCAEventId -Level ERROR -Message '[MissingPath] C:\Missing: not found' | Should -Be 2103
    }
}
