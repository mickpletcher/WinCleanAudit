Describe 'WinCleanAudit entry script' {
    It 'exposes NoBrowserLaunch' {
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            "$PSScriptRoot\..\..\src\WinCleanAudit.ps1",
            [ref]$tokens,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
        $ast.ParamBlock.Parameters.Name.VariablePath.UserPath | Should -Contain 'NoBrowserLaunch'
    }

    It 'guards browser launch behind NoBrowserLaunch' {
        $content = Get-Content -Path "$PSScriptRoot\..\..\src\WinCleanAudit.ps1" -Raw

        $content | Should -Match 'if \(-not \$NoBrowserLaunch\)'
        $content | Should -Match 'Start-Process -FilePath \$writtenHtmlReport'
    }
}
