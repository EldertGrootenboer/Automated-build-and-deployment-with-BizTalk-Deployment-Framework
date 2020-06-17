$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Undeploy" {

    Context 'function UndeployBizTalkApplications' { It 'needs testing' { } }
    Context 'function UndeployBizTalkApplication' { It 'needs testing' { } }
}
