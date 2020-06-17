$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Install" {

    Context 'function InstallBizTalkApplications' { It 'needs testing' { } }
    Context 'function InstallBizTalkApplication' { It 'needs testing' { } }
}
