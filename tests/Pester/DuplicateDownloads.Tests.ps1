BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\DuplicateDownloads.psm1" -Force
}

Describe 'DuplicateDownloads' {
    It 'imports and exposes functions' {
        Get-Command Get-DuplicateDownloads -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-DuplicateDownloadsReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'is audit only' {
        $result = Invoke-DuplicateDownloadsReport
        $result.Mode | Should -Be 'DryRun'
        $result.ItemsModified | Should -Be 0
    }
}
