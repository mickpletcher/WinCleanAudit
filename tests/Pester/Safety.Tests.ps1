BeforeAll {
    Import-Module "$PSScriptRoot\..\..\src\modules\Safety.psm1" -Force
}

Describe 'Safety' {
    It 'imports and exposes functions' {
        Get-Command Confirm-WCAAction -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Test-WCAProtectedPath -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-WCAProtectedLocations -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-WCARedirectedKnownFolderLocations -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Normalize-WCAPath -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'returns protected locations' {
        @(Get-WCAProtectedLocations).Count | Should -BeGreaterThan 0
    }

    It 'normalizes quoted paths and trailing separators' {
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        Normalize-WCAPath -Path "`"$userProfile\Documents\`"" | Should -Be (Join-Path $userProfile 'Documents')
    }

    It 'treats protected location child paths as protected' {
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        Test-WCAProtectedPath -Path (Join-Path $userProfile 'Documents\cleanup.tmp') | Should -BeTrue
    }

    It 'does not protect sibling paths that only share a prefix' {
        $userProfile = [Environment]::GetFolderPath('UserProfile')
        Test-WCAProtectedPath -Path (Join-Path $userProfile 'DocumentsArchive\cleanup.tmp') | Should -BeFalse
    }

    It 'treats cloud sync paths as protected' {
        $userProfile = [Environment]::GetFolderPath('UserProfile')

        Test-WCAProtectedPath -Path (Join-Path $userProfile 'OneDrive\cleanup.tmp') | Should -BeTrue
        Test-WCAProtectedPath -Path (Join-Path $userProfile 'OneDrive - Contoso\cleanup.tmp') | Should -BeTrue
        Test-WCAProtectedPath -Path (Join-Path $userProfile 'Dropbox\cleanup.tmp') | Should -BeTrue
        Test-WCAProtectedPath -Path (Join-Path $userProfile 'Google Drive\cleanup.tmp') | Should -BeTrue
    }

    It 'returns redirected known folder registry paths' {
        InModuleScope Safety {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    Personal = '\\fileserver\users\mick\Documents'
                    Desktop = '%USERPROFILE%\RedirectedDesktop'
                }
            }

            $locations = Get-WCARedirectedKnownFolderLocations

            $locations | Should -Contain '\\fileserver\users\mick\Documents'
            $locations | Should -Contain "$env:USERPROFILE\RedirectedDesktop"
        }
    }

    It 'treats redirected known folder child paths as protected' {
        InModuleScope Safety {
            Mock Get-ItemProperty {
                [PSCustomObject]@{
                    Personal = '\\fileserver\users\mick\Documents'
                }
            }

            Test-WCAProtectedPath -Path '\\fileserver\users\mick\Documents\cleanup.tmp' | Should -BeTrue
        }
    }
}
