$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Uninstall" {

    Context 'function UninstallBizTalkApplications' { It 'needs testing' { } }
    Context 'function UninstallBizTalkApplication' { It 'needs testing' { } }
}
