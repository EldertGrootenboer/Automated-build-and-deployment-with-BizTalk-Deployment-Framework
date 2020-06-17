# Load parameters
$settings = Import-Csv Settings_DeploymentEnvironment.csv
foreach ($setting in $settings) {
    # Program Files directory where application should be installed
    if ($setting.'Name;Value'.Split(";")[0].Trim() -eq "programFilesDirectory") { $programFilesDirectory = $setting.'Name;Value'.Split(";")[1].Trim() }

    # Suffix as set in in the ProductName section of the BTDF project file. By default this is " for BizTalk".
    if ($setting.'Name;Value'.Split(";")[0].Trim() -eq "productNameSuffix") { $productNameSuffix = $setting.'Name;Value'.Split(";")[1].TrimEnd() }

    # Indicator if we should deploy to the BizTalkMgmtDB database from this server. In multi-server environments this should be true on 1 server, and false on the others
    if ($setting.'Name;Value'.Split(";")[0].Trim() -eq "deployBizTalkMgmtDB") { $deployBizTalkMgmtDB = $setting.'Name;Value'.Split(";")[1].Trim() }
}

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
