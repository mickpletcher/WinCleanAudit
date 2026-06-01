BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\Safety.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\TempCleanup.psm1" -Force
}

Describe 'TempCleanup' {
    It 'imports and exposes functions' {
        Get-Command Get-TempCleanupAudit -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-TempCleanup -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'defaults to DryRun behavior' {
        $result = Invoke-TempCleanup
        $result.Mode | Should -Be 'DryRun'
        $result.ItemsModified | Should -Be 0
    }

    It 'blocks NoPrompt without Execute' {
        { Invoke-TempCleanup -NoPrompt } | Should -Throw
    }
}
