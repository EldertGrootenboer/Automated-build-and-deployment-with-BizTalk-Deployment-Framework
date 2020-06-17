$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Script $sut" {

    Context 'function Uninstall-BizTalkApplication' {

        BeforeAll {
            New-Item -ItemType File -Path "$TestDrive\Dummy.msi"
        }

        It 'accepts a Path' {
            Uninstall-BizTalkApplication -WhatIf `
                -Path $TestDrive
        }

        It 'accepts File(s)' {
            Uninstall-BizTalkApplication -WhatIf `
                -File "$TestDrive\Dummy.msi"
        }
    }
}
