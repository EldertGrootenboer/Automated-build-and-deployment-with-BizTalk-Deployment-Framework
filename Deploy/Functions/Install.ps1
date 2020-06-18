# Import general helpers using dot operator
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


# Install application(s)
function Install-BizTalkApplication {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess, DefaultParameterSetName = 'ByPath')]
    Param(
        [Parameter(ParameterSetName = 'ByPath')]
        [string] $Path,

        [Parameter(ParameterSetName = 'ByFile', ValueFromPipeline)]
        [System.IO.FileInfo] $File
    )

    Process {
        switch ($PSCmdlet.ParameterSetName) {

            'ByPath' {

                $files = Get-MsiFile $Path
                $files | Install-BizTalkApplication
            }

            'ByFile' {

                if ($PSCmdlet.ShouldProcess($File.Name)) {
                    # Get application name and version
                    # We assume msi file name is in the format ApplicationName-Version
                    $application = $File.BaseName.Split("-")[0]
                    $version = $File.BaseName.Split("-")[1]

                    # Directory where MSI resides
                    $msiDirectory = $File.Directory

                    # Set log name
                    $logFileName = "$msiDirectory\$application.log"

                    # Set installer path
                    $msiPath = $File.FullName

                    # Install application
                    Start-Process -WindowStyle Hidden -FilePath "msiexec.exe" -ArgumentList "/i ""$msiPath"" /quiet /log ""$logFileName"" INSTALLDIR=""$programFilesDirectory\$application$productNameSuffix\$version""" -Wait -Passthru | Out-Null

                    # Check if installation was successful
                    if ((Select-String -Path $logFileName -Pattern "success or error status: 0" -Quiet) -eq "true") {
                        Write-Information "$applicationName uninstalled successfully"
                    }
                    else {
                        Write-Error "$applicationName not uninstalled successfully"
                    }
                }
            }
        }
    }
}
