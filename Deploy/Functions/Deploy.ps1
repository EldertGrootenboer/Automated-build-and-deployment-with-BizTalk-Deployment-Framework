# Import custom functions
. "$PsScriptRoot\General.ps1"

# Load parameters
$settings = Import-Csv Settings_DeploymentEnvironment.csv
foreach ($setting in $settings) {
    # Program Files directory where application should be installed
    if ($setting.'Name;Value'.Split(";")[0].Trim() -eq "programFilesDirectory") { $programFilesDirectory = $setting.'Name;Value'.Split(";")[1].Trim() }

    # Suffix as set in in the ProductName section of the BTDF project file. By default this is " for BizTalk".
    if ($setting.'Name;Value'.Split(";")[0].Trim() -eq "productNameSuffix") { $productNameSuffix = $setting.'Name;Value'.Split(";")[1].TrimEnd() }

    # Indicator if we should deploy to the BizTalkMgmtDB database from this server. In multi-server environments this should be true on 1 server, and false on the others
    if ($setting.'Name;Value'.Split(";")[0].Trim() -eq "deployBizTalkMgmtDB") { $deployBizTalkMgmtDB = $setting.'Name;Value'.Split(";")[1].Trim() }

    # Name of the BTDF environment settings file for this environment.
    if ($setting.'Name;Value'.Split(";")[0].Trim() -eq "environmentSettingsFileName") { $environmentSettingsFileName = $setting.'Name;Value'.Split(";")[1].Trim() }
}

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
