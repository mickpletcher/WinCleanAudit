BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\Safety.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\ReportWriter.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\LargeFileReport.psm1" -Force
}

Describe 'LargeFileReport' {
    It 'imports and exposes functions' {
        Get-Command Get-LargeFiles -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-LargeFileReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'defaults to 500 MB threshold' {
        $result = Invoke-LargeFileReport
        $result.Mode | Should -Be 'DryRun'
    }
}
