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

    It 'records delete and service actions during Execute' {
        InModuleScope WindowsUpdateCache {
            Mock Test-WCAIsAdministrator { $true }
            Mock Get-Service { [PSCustomObject]@{ Name = $Name; Status = 'Running' } }
            Mock Stop-Service {}
            Mock Start-Service {}
            Mock Get-ChildItem { [PSCustomObject]@{ FullName = 'C:\Windows\SoftwareDistribution\Download\a.tmp'; PSIsContainer = $false; Length = 1024 } }
            Mock Remove-Item {}

            $result = Clear-WindowsUpdateCache -Execute -NoPrompt

            $result.ExecutionLog.Action | Should -Contain 'Service'
            $result.ExecutionLog.Action | Should -Contain 'Delete'
            $result.ExecutionLog.Status | Should -Contain 'Validated'
            $result.ExecutionLog.Operation | Should -Contain 'Remove Windows Update cache item'
        }
    }

    It 'warns when restarted services do not validate as running' {
        InModuleScope WindowsUpdateCache {
            $script:getServiceCalls = 0
            Mock Test-WCAIsAdministrator { $true }
            Mock Get-Service {
                $script:getServiceCalls++
                if ($script:getServiceCalls -le 3) {
                    return [PSCustomObject]@{ Name = $Name; Status = 'Running' }
                }
                return [PSCustomObject]@{ Name = $Name; Status = 'Stopped' }
            }
            Mock Stop-Service {}
            Mock Start-Service {}
            Mock Get-ChildItem { @() }
            Mock Remove-Item {}

            $result = Clear-WindowsUpdateCache -Execute -NoPrompt

            $result.Status | Should -Be 'Warning'
            $result.Warnings -join '; ' | Should -Match 'Validate service restart'
            $result.ExecutionLog | Where-Object {
                $_.Operation -eq 'Validate service restart' -and $_.Status -eq 'Failed'
            } | Should -Not -BeNullOrEmpty
        }
    }
}
