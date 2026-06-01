BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Results.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\Safety.psm1" -Force
    Import-Module "$PSScriptRoot\..\..\src\modules\WindowsUpdateCache.psm1" -Force
}

Describe 'WindowsUpdateCache' {
    It 'imports and exposes functions' {
        Get-Command Get-WindowsUpdateCacheInfo -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Clear-WindowsUpdateCache -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Invoke-WindowsUpdateCacheTask -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'runs audit in DryRun' {
        $result = Invoke-WindowsUpdateCacheTask -DryRun
        $result.Mode | Should -Be 'DryRun'
    }

    It 'blocks NoPrompt without Execute' {
        { Invoke-WindowsUpdateCacheTask -NoPrompt } | Should -Throw
    }
}
