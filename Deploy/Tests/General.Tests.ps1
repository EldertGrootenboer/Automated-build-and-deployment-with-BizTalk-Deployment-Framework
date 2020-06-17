$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$PsScriptRoot\..\Functions\$sut"

Describe "General" {

    Context 'function WaitForKeyPress' { It 'needs testing' { } }
    Context 'function ClearLogFiles' { It 'needs testing' { } }
    Context 'function CheckIfIISShouldBeReset' { It 'needs testing' { } }
    Context 'function CheckIfHostinstancesShouldBeRestarted' { It 'needs testing' { } }
    Context 'function GetYesNoAnswer' { It 'needs testing' { } }
    Context 'function DoIISReset' { It 'needs testing' { } }
    Context 'function DoHostInstancesRestart' { It 'needs testing' { } }
    Context 'function ExecuteSqlFile' { It 'needs testing' { } }
    Context 'function ImportRegistryFile' { It 'needs testing' { } }
    Context 'function GetRegistryFiles' { It 'needs testing' { } }
    Context 'function GetSQLFiles' { It 'needs testing' { } }
    Context 'function GetMsiFiles' { It 'needs testing' { } }
}
