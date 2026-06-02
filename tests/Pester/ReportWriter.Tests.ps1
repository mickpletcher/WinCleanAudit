BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\ReportWriter.psm1" -Force
}

Describe 'ReportWriter' {
    It 'imports and exposes functions' {
        Get-Command New-WinCleanReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command ConvertTo-ReadableSize -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Add-ReportSection -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-MarkdownReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-HtmlReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-JsonReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Write-CsvReport -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Remove-OldWCAReports -ErrorAction Stop | Should -Not -BeNullOrEmpty
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
        $path = Write-MarkdownReport -Report $report -OutputFolder $tmp -Timestamp '20260601-201500'
        Split-Path -Leaf $path | Should -Be 'cleanup-report-20260601-201500.md'
        Test-Path $path | Should -BeTrue
    }

    It 'writes html report with required name pattern' {
        $result = [PSCustomObject]@{
            TaskName='Test'; Module='Test'; Status='Success'; Mode='DryRun'; ItemsScanned=0; ItemsModified=0; EstimatedBytes=0; RecoveredBytes=0; ActionsTaken=@('Scanned only'); Warnings=@(); Errors=@(); Recommendations=@(); Details=@(); Duration=0
        }
        $report = New-WinCleanReport -Mode DryRun -Results @($result)
        $tmp = Join-Path $env:TEMP 'wca-tests-report'
        $path = Write-HtmlReport -Report $report -OutputFolder $tmp -Timestamp '20260601-201500'
        Split-Path -Leaf $path | Should -Be 'cleanup-report-20260601-201500.html'
        Test-Path $path | Should -BeTrue
        Get-Content -Raw -Path $path | Should -Match '<!doctype html>'
    }

    It 'writes json report with required name pattern' {
        $result = [PSCustomObject]@{
            TaskName='Test'; Module='Test'; Status='Success'; Mode='DryRun'; ItemsScanned=1; ItemsModified=0; EstimatedBytes=1024; RecoveredBytes=0; ActionsTaken=@('Scanned only'); Warnings=@(); Errors=@(); Recommendations=@(); Details=@(); Duration=0
        }
        $report = New-WinCleanReport -Mode DryRun -Results @($result)
        $tmp = Join-Path $env:TEMP 'wca-tests-report'
        $path = Write-JsonReport -Report $report -OutputFolder $tmp -Timestamp '20260601-201500'
        Split-Path -Leaf $path | Should -Be 'cleanup-report-20260601-201500.json'
        Test-Path $path | Should -BeTrue
        (Get-Content -Raw -Path $path | ConvertFrom-Json).Mode | Should -Be 'DryRun'
    }

    It 'writes csv report with required name pattern' {
        $result = [PSCustomObject]@{
            TaskName='Test'; Module='Test'; Status='Success'; Mode='DryRun'; ItemsScanned=1; ItemsModified=0; EstimatedBytes=1024; RecoveredBytes=0; ActionsTaken=@('Scanned only'); Warnings=@(); Errors=@(); Recommendations=@(); Details=@(); Duration=0
        }
        $report = New-WinCleanReport -Mode DryRun -Results @($result)
        $tmp = Join-Path $env:TEMP 'wca-tests-report'
        $path = Write-CsvReport -Report $report -OutputFolder $tmp -Timestamp '20260601-201500'
        Split-Path -Leaf $path | Should -Be 'cleanup-report-20260601-201500.csv'
        Test-Path $path | Should -BeTrue
        (Import-Csv -Path $path)[0].Module | Should -Be 'Test'
    }

    It 'removes old generated report files by retention policy' {
        $tmp = Join-Path $env:TEMP 'wca-tests-retention'
        if (-not (Test-Path $tmp)) {
            New-Item -Path $tmp -ItemType Directory -Force | Out-Null
        }

        $oldReport = Join-Path $tmp 'cleanup-report-old.md'
        $newReport = Join-Path $tmp 'cleanup-report-new.md'
        $ignoredFile = Join-Path $tmp 'notes.txt'
        'old' | Set-Content -Path $oldReport
        'new' | Set-Content -Path $newReport
        'ignore' | Set-Content -Path $ignoredFile
        (Get-Item $oldReport).LastWriteTime = (Get-Date).AddDays(-40)
        (Get-Item $newReport).LastWriteTime = Get-Date
        (Get-Item $ignoredFile).LastWriteTime = (Get-Date).AddDays(-40)

        $result = Remove-OldWCAReports -OutputFolder $tmp -RetentionDays 30 -IncludeExtensions @('.md')

        $result.Removed | Should -Be 1
        Test-Path $oldReport | Should -BeFalse
        Test-Path $newReport | Should -BeTrue
        Test-Path $ignoredFile | Should -BeTrue
    }
}
