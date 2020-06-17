$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Deploy" {

    Context 'function DeployBizTalkApplications' { It 'needs testing' { } }
    Context 'function DeployBizTalkApplication' { It 'needs testing' { } }
}
