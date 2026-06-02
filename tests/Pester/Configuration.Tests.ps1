BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Configuration.psm1" -Force
}

Describe 'Configuration' {
    It 'imports and exposes functions' {
        Get-Command Get-WCAConfiguration -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-WCAPolicyProfile -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-WCAConfiguration -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'loads module entry points from configuration' {
        $config = Get-WCAConfiguration

        $config.modules.entry_points.TempCleanup | Should -Be 'Invoke-TempCleanup'
        $config.modules.entry_points.WindowsUpdateCache | Should -Be 'Invoke-WindowsUpdateCacheTask'
    }

    It 'loads the selected policy profile' {
        $config = Get-WCAConfiguration
        $profile = Get-WCAPolicyProfile -Configuration $config

        $profile.Name | Should -Be 'default'
        $profile.Profile.reporting.retention_days | Should -Be 30
    }

    It 'loads the enterprise audit policy profile' {
        $config = Get-WCAConfiguration
        $config.execution.policy_profile = 'enterprise_audit'
        $profile = Get-WCAPolicyProfile -Configuration $config

        $profile.Name | Should -Be 'enterprise_audit'
        $profile.Profile.reporting.json_export | Should -BeTrue
        $profile.Profile.logging.event_log_enabled | Should -BeTrue
    }

    It 'validates missing policy profiles' {
        $config = Get-WCAConfiguration
        $config.execution.policy_profile = 'missing'
        $result = Test-WCAConfiguration -Configuration $config

        $result.IsValid | Should -BeFalse
        $result.Errors | Should -Contain 'policy_profiles.missing is required'
    }
}
