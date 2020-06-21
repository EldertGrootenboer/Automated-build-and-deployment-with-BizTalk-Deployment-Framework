$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Script $sut" {

    Context 'function Deploy-BizTalkApplication' {

        It 'accepts a ordered set of applications' {
            Deploy-BizTalkApplication -WhatIf `
                -ApplicationsInOrderOfDeployment @('Contoso.OrderSystem.Orders', 'Contoso.OrderSystem.Invoices', 'Contoso.OrderSystem.Payments') `
                -Versions @('1.1.0', '1.1.0', '1.1.0') `
                -ScriptsDirectory $TestDrive
        }

        It 'accepts a single application' {
            Deploy-BizTalkApplication -WhatIf `
                -Application 'Contoso.OrderSystem.Orders' `
                -Version '1.1.0'
        }
    }
}
