BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\ReportWriter.psm1" -Force
}

Describe 'ReportWriter' {
    It 'imports and exposes functions' {
        Get-Command New-WinCleanReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertTo-ReadableSize -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-ReportSection -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-MarkdownReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'converts bytes to readable values' {
        ConvertTo-ReadableSize -Bytes 0 | Should -Be '0 B'
        (ConvertTo-ReadableSize -Bytes 1024) | Should -Match 'KB'
    }

    It 'writes markdown report with required name pattern' {
        $result = [PSCustomObject]@{
            TaskName='Test'; Module='Test'; Status='Success'; Mode='DryRun'; ItemsScanned=0; ItemsModified=0; EstimatedBytes=0; RecoveredBytes=0; ActionsTaken=@(); Warnings=@(); Errors=@(); Recommendations=@(); Details=@(); Duration=0
        }
        $report = New-WinCleanReport -Mode DryRun -Results @($result)
        $tmp = Join-Path $env:TEMP 'wca-tests-report'
        $path = Write-MarkdownReport -Report $report -OutputFolder $tmp
        Split-Path -Leaf $path | Should -Match '^cleanup-report-\d{8}-\d{6}\.md$'
        Test-Path $path | Should -BeTrue
    }
}
