$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "Build" {

    Context 'function BuildAndCreateBizTalkInstallers' { It 'needs testing' { } }
    Context 'function BuildAndCreateBizTalkInstaller' { It 'needs testing' { } }
    Context 'function BuildBizTalkApplication' { It 'needs testing' { } }
    Context 'function BuildBizTalkMsi' { It 'needs testing' { } }
}
