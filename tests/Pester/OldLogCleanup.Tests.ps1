BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\Safety.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\OldLogCleanup.psm1" -Force
}

Describe 'OldLogCleanup' {
    It 'imports and exposes functions' {
        Get-Command Get-OldLogSummary -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Clear-OldLogs -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-OldLogCleanup -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'uses DryRun by default' {
        $result = Invoke-OldLogCleanup
        $result.Mode | Should -Be 'DryRun'
    }

    It 'blocks NoPrompt without Execute' {
        { Invoke-OldLogCleanup -NoPrompt } | Should -Throw
    }
}
