BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\Safety.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\RecycleBin.psm1" -Force
}

Describe 'RecycleBin' {
    It 'imports and exposes functions' {
        Get-Command Get-RecycleBinSummary -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Clear-WinCleanRecycleBin -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-RecycleBinCleanup -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'runs DryRun without deletion' {
        $result = Invoke-RecycleBinCleanup -DryRun
        $result.Mode | Should -Be 'DryRun'
        $result.ItemsModified | Should -Be 0
    }

    It 'blocks NoPrompt without Execute' {
        { Invoke-RecycleBinCleanup -NoPrompt } | Should -Throw
    }
}
