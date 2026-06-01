BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\Safety.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\BrowserCache.psm1" -Force
}

Describe 'BrowserCache' {
    It 'imports and exposes functions' {
        Get-Command Get-BrowserCacheSummary -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Clear-BrowserCache -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-BrowserCacheCleanup -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'runs in DryRun mode' {
        $result = Invoke-BrowserCacheCleanup -DryRun
        $result.Mode | Should -Be 'DryRun'
        $result.ItemsModified | Should -Be 0
    }

    It 'blocks NoPrompt without Execute' {
        { Invoke-BrowserCacheCleanup -NoPrompt } | Should -Throw
    }
}
