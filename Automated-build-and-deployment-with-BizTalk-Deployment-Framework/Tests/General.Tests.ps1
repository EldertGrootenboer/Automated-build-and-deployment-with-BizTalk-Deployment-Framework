$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Script $sut" {

    Context 'function Restart-IIS' { It 'needs testing' { } }

    Context 'function Restart-HostInstances' { It 'needs testing' { } }

    Context 'function Invoke-SqlFile' { It 'needs testing' { } }

    Context 'function Import-RegistryFile' { It 'needs testing' { } }

    Context 'function Get-RegistryFile' {

        BeforeAll {
            New-Item -ItemType File -Path "$TestDrive\Dummy.reg"
            New-Item -ItemType File -Path "$TestDrive\Folder\Dummy.reg" -Force
        }

        It 'finds a *.reg file' {
            Get-RegistryFile -Path $TestDrive |
                Should HaveCount 1
        }
    }

    Context 'function Get-SqlFile' {

        BeforeAll {
            New-Item -ItemType File -Path "$TestDrive\Dummy.sql"
            New-Item -ItemType File -Path "$TestDrive\Folder\Dummy.sql" -Force
        }

        It 'finds a *.sql file' {
            Get-SqlFile -Path $TestDrive |
                Should HaveCount 1
        }
    }

    Context 'function Get-MsiFile' {

        BeforeAll {
            New-Item -ItemType File -Path "$TestDrive\Dummy.msi"
            New-Item -ItemType File -Path "$TestDrive\Folder\Dummy.msi" -Force
        }

        It 'finds a *.msi file' {
            Get-MsiFile -Path $TestDrive |
                Should HaveCount 1
        }
    }
}
