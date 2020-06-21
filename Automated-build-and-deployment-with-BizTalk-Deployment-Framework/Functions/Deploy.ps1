# Import custom functions
. "$PsScriptRoot\General.ps1"

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


# Deploy BizTalk Application(s)
function Deploy-BizTalkApplication {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess, DefaultParameterSetName = 'BySet')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'BySet')]
        [string[]] $ApplicationsInOrderOfDeployment,

        [Parameter(Mandatory, ParameterSetName = 'BySet')]
        [string[]] $Versions,

        [Parameter(Mandatory, ParameterSetName = 'BySet')]
        [string] $ScriptsDirectory,

        [Parameter(Mandatory, ParameterSetName = 'ByApplication')]
        [string] $Application,

        [Parameter(Mandatory, ParameterSetName = 'ByApplication')]
        [string] $Version
    )

    Process {
        switch ($PSCmdlet.ParameterSetName) {

            'BySet' {
                # Loop through applications to be deployed
                for ($index = 0; $index -lt $ApplicationsInOrderOfDeployment.Length; $index++) {
                    # Deploy application
                    Deploy-BizTalkApplication -Application $ApplicationsInOrderOfDeployment[$index] -Version $Versions[$index]
                }

                # SQL files to be executed
                Get-SqlFile $ScriptsDirectory | Invoke-SqlFile

                # Registry files to be imported
                Get-RegistryFile $ScriptsDirectory | Import-RegistryFile

                # Do restarts
                Restart-IIS
                Restart-HostInstances
            }

            'ByApplication' {

                if ($PSCmdlet.ShouldProcess("$Application ($Version)")) {

                    # Set log file
                    $logFileName = "$programFilesDirectory\$Application$productNameSuffix\$Version\DeployResults\DeployResults.txt"

                    # Execute deployment
                    $exitCode = (Start-Process -WindowStyle Hidden -FilePath "$env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" -ArgumentList "/p:DeployBizTalkMgmtDB=$deployBizTalkMgmtDB;Configuration=Server;SkipUndeploy=true /target:Deploy /l:FileLogger,Microsoft.Build.Engine;logfile=""$programFilesDirectory\$Application$productNameSuffix\$Version\DeployResults\DeployResults.txt"" ""$programFilesDirectory\$Application$productNameSuffix\$Version\Deployment\Deployment.btdfproj"" /p:ENV_SETTINGS=""$programFilesDirectory\$Application$productNameSuffix\$Version\Deployment\EnvironmentSettings\$environmentSettingsFileName.xml""" -Wait -Passthru).ExitCode

                    # Check if deployment was successful
                    if ($exitCode -eq 0 -and (Select-String -Path $logFileName -Pattern "0 Error(s)" -Quiet) -eq "true") {
                        Write-Information "$Application ($Version) deployed successfully"
                    }
                    else {
                        Write-Error "$Application ($Version) could not be deployed successfully"
                    }
                }
            }
        }
    }
}
