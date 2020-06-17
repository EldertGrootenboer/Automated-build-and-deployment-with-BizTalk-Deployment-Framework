$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Script $sut" {

    Context 'function Undeploy-BizTalkApplication' {

        It 'accepts a ordered set of applications' {
            Undeploy-BizTalkApplication -WhatIf `
                -ApplicationsInOrderOfUnDeployment @('Contoso.OrderSystem.Payments', 'Contoso.OrderSystem.Invoices', 'Contoso.OrderSystem.Orders') `
                -Versions @('1.0.0', '1.0.0', '1.0.0')
        }

        It 'accepts a single application' {
            Undeploy-BizTalkApplication -WhatIf `
                -Application 'Contoso.OrderSystem.Orders' `
                -Version '1.0.0'
        }
    }
}
