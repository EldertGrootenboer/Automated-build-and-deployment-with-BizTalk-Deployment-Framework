$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Script $sut" {

    Context 'function Build-BizTalkInstaller' {

        It 'accepts a set of application(s)' {
            ('Contoso.OrderSystem.Orders', 'Contoso.OrderSystem.Invoices', 'Contoso.OrderSystem.Payments') | `
                Build-BizTalkInstaller -WhatIf -Project 'OrderSystem'
        }
    }

    Context 'function BuildAndCreateBizTalkInstaller' {

        It 'accepts a single application' {
            BuildAndCreateBizTalkInstaller -WhatIf `
                -Application 'Contoso.OrderSystem.Orders' `
                -Project 'OrderSystem'
        }
    }

    Context 'function Build-BizTalkApplication' {

        It 'accepts a single application' {
            Build-BizTalkApplication -WhatIf `
                -Application 'Contoso.OrderSystem.Orders' `
                -Project 'OrderSystem'
        }
    }

    Context 'function Build-BizTalkMsi' {

        It 'accepts a single application' {
            Build-BizTalkMsi -WhatIf `
                -Application 'Contoso.OrderSystem.Orders' `
                -Project 'OrderSystem'
        }
    }
}
