# Load parameters
$settings = Import-Csv Settings_DeploymentEnvironment.csv
foreach ($setting in $settings) {
    # Directory where BizTalk installation resides
    if ($setting.'Name;Value'.Split(";")[0].Trim() -eq "bizTalkServerInstallationDirectory") { $bizTalkServerInstallationDirectory = $setting.'Name;Value'.Split(";")[1].Trim() }

    # Database server for the environment
    if ($setting.'Name;Value'.Split(";")[0].Trim() -eq "databaseServer") { $databaseServer = $setting.'Name;Value'.Split(";")[1].Trim() }
}

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
