$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Script $sut" {

    Context 'function Install-BizTalkApplication' {

        BeforeAll {
            New-Item -ItemType File -Path "$TestDrive\Dummy.msi"
        }

        It 'accepts a Path' {
            Install-BizTalkApplication -WhatIf `
                -Path $TestDrive
        }

        It 'accepts File(s)' {
            Install-BizTalkApplication -WhatIf `
                -File "$TestDrive\Dummy.msi"
        }
    }
}
