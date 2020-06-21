
# Load settings
$settings = Import-Csv "$PsScriptRoot\..\Settings_DeploymentEnvironment.csv" -Delimiter ';'

# Program Files directory where application should be installed
$programFilesDirectory = ($settings | Where Name -eq 'programFilesDirectory').Value
# Suffix as set in in the ProductName section of the BTDF project file. By default this is " for BizTalk".
$productNameSuffix = ($settings | Where Name -eq '$productNameSuffix').Value
# Indicator if we should deploy to the BizTalkMgmtDB database from this server. In multi-server environments this should be true on 1 server, and false on the others
$deployBizTalkMgmtDB = ($settings | Where Name -eq 'deployBizTalkMgmtDB').Value
# Name of the BTDF environment settings file for this environment.
$environmentSettingsFileName = ($settings | Where Name -eq 'environmentSettingsFileName').Value
# Directory where BizTalk installation resides
$bizTalkServerInstallationDirectory = ($settings | Where Name -eq 'bizTalkServerInstallationDirectory').Value
# Database server for the environment
$databaseServer = ($settings | Where Name -eq 'databaseServer').Value


# Undeploy BizTalk Application(s)
function Undeploy-BizTalkApplication {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess, DefaultParameterSetName = 'BySet')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'BySet')]
        [string[]] $ApplicationsInOrderOfUndeployment,

        [Parameter(Mandatory, ParameterSetName = 'BySet')]
        [string[]] $Versions,

        [Parameter(Mandatory, ParameterSetName = 'ByApplication')]
        [string] $Application,

        [Parameter(Mandatory, ParameterSetName = 'ByApplication')]
        [string] $Version
    )

    Process {
        switch ($PSCmdlet.ParameterSetName) {

            'BySet' {
                # Loop through applications to be undeployed
                for ($index = 0; $index -lt $ApplicationsInOrderOfUndeployment.Length; $index++) {
                    # Deploy application
                    Undeploy-BizTalkApplication -Application $ApplicationsInOrderOfUndeployment[$index] -Version $Versions[$index]
                }
            }

            'ByApplication' {

                if ($PSCmdlet.ShouldProcess("$Application ($Version)")) {
                    # Execute undeployment
                    $exitCode = (Start-Process -WindowStyle Hidden -FilePath "$env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" -ArgumentList """$programFilesDirectory\$Application$productNameSuffix\$Version\Deployment\Deployment.btdfproj"" /t:Undeploy /p:DeployBizTalkMgmtDB=$deployBizTalkMgmtDB /p:Configuration=Server" -Wait -Passthru).ExitCode

                    if ($exitCode -eq 0) {
                        Write-Information "$Application ($Version) undeployed successfully"
                    }
                    else {
                        Write-Error "$Application ($Version) not undeployed successfully"
                    }
                }
            }
        }
    }
}
