
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



# Do IIS reset
function Restart-IIS {
    [CmdletBinding(ConfirmImpact = 'Low', SupportsShouldProcess)]
    Param(
    )

    if ($PSCmdlet.ShouldProcess('localhost')) {

        # FIX this will result in an endless loop when iisreset is not present
        <#
        while (!$result) {
            iisreset
            $result = $?
        }
        #>
    }
}

# Do hostinstances restart
function Restart-HostInstances {
    [CmdletBinding(ConfirmImpact = 'Low', SupportsShouldProcess)]
    Param(
    )

    if ($PSCmdlet.ShouldProcess('localhost')) {
        cscript.exe "$bizTalkServerInstallationDirectory\SDK\Samples\ApplicationDeployment\VisualStudioHostRestart\RestartBizTalkHostInstances.vbs"
    }
}

# Run a SQL command file
function Invoke-SqlFile {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Path
    )

    Process {
        if ($PSCmdlet.ShouldProcess($Path)) {
            Start-Process -FilePath "sqlcmd" -ArgumentList "-S $databaseServer -i ""$Path""" -Wait -PassThru | Out-Null
        }
    }
}

# Import registry file
function Import-RegistryFile {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Path
    )

    Process {
        if ($PSCmdlet.ShouldProcess($Path)) {
            regedit /s $Path
        }
    }
}

# Get registry files in a directory
function Get-RegistryFile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    # Get registry files
    Get-ChildItem $Path -Filter *.reg
}

# Get SQL files in a directory
function Get-SqlFile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    # Get SQL files
    Get-ChildItem $Path -Filter *.sql
}

# Get MSI files in a directory
function Get-MsiFile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    # Get MSI files
    Get-ChildItem $Path -Filter *.msi
}
