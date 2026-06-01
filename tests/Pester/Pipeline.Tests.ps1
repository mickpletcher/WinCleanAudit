BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Pipeline.psm1" -Force
    function global:Invoke-TestWCAModule {
        param(
            [switch]$DryRun,
            [switch]$Execute,
            [switch]$NoPrompt
        )

        [PSCustomObject]@{
            TaskName        = 'Test'
            Module          = 'TestModule'
            Status          = 'Success'
            Mode            = if ($Execute) { 'Execute' } else { 'DryRun' }
            ItemsScanned    = 1
            ItemsModified   = 0
            EstimatedBytes  = 0
            RecoveredBytes  = 0
            ActionsTaken    = @()
            Warnings        = @()
            Errors          = @()
            Recommendations = @()
            Details         = @()
            Duration        = 0
        }
    }
}

AfterAll {
    Remove-Item -Path function:\global:Invoke-TestWCAModule -ErrorAction SilentlyContinue
}

Describe 'Pipeline' {
    It 'imports and exposes functions' {
        Get-Command Invoke-WCAPipeline -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-WCAModule -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'uses configured entry points' {
        $entryPoints = @{
            TestModule = 'Invoke-TestWCAModule'
        }

        $result = Invoke-WCAPipeline -Modules @('TestModule') -EntryPoints $entryPoints -DryRun

        $result.Module | Should -Be 'TestModule'
        $result.Status | Should -Be 'Success'
        $result.Mode | Should -Be 'DryRun'
    }

    It 'returns an error result when an entry point is missing' {
        $result = Invoke-WCAPipeline -Modules @('MissingModule') -EntryPoints @{} -DryRun

        $result.Module | Should -Be 'MissingModule'
        $result.Status | Should -Be 'Error'
        $result.Errors[0] | Should -Match 'No configured entry point'
    }
}
