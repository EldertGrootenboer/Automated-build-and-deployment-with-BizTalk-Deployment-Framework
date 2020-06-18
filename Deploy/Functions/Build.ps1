# Import general helpers using dot operator
. "$PsScriptRoot\General.ps1"

# Load settings
$settings = Import-Csv "$PsScriptRoot\..\Settings_BuildEnvironment.csv" -Delimiter ';'

# The directory where the BizTalk projects are stored
$projectsBaseDirectory = ($settings | Where Name -eq 'projectsBaseDirectory').Value
# The directory where the MSI's should be saved to
$installersOutputDirectory  = ($settings | Where Name -eq 'installersOutputDirectory').Value
# Directory where Visual Studio resides
$visualStudioDirectory = ($settings | Where Name -eq 'visualStudioDirectory').Value


# Build and create installers for BizTalk application(s)
function Build-BizTalkInstaller {
    [CmdletBinding(ConfirmImpact = 'Medium', SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Application,

        [Parameter(Mandatory)]
        [string] $Project
    )

    Process {
        if ($PSCmdlet.ShouldProcess("$Application ($Project)")) {
            Build-BizTalkApplication -Application $Application -Project $Project
            Build-BizTalkMsi -Application $Application -Project $Project
        }
    }
}

# Build a BizTalk application
function Build-BizTalkApplication {
    [CmdletBinding(ConfirmImpact = 'Low', SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)]
        [string] $Application,

        [Parameter(Mandatory)]
        [string] $Project
    )

    Process {
        if ($PSCmdlet.ShouldProcess("$Application ($Project)")) {

            # Set directory where the BizTalk projects for the current project are stored
            $projectsDirectory = "$projectsBaseDirectory\$Project"

            # Build application
            Write-Information  "Building $Application"
            $exitCode = (Start-Process -FilePath "$visualStudioDirectory\Common7\IDE\devenv.exe" -ArgumentList """$projectsDirectory\$Application\$Application.sln"" /Build Release /Out $Application.log" -PassThru -Wait).ExitCode

            # Check result
            if ($exitCode -eq 0 -and (Select-String -Path "$Application.log" -Pattern "0 failed" -Quiet) -eq "true") {
                Write-Information  "$Application built succesfully"
            }
            else {
                Write-Error "$Application not built succesfully"
            }
        }
    }
}

# Build MSI for a BizTalk application
function Build-BizTalkMsi {
    [CmdletBinding(ConfirmImpact = 'Low', SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory)]
        [string] $Application,

        [Parameter(Mandatory)]
        [string] $Project
    )

    Process {
        if ($PSCmdlet.ShouldProcess("$Application ($Project)")) {

            # Set directory where the BizTalk projects for the current project are stored
            $projectsDirectory = "$projectsBaseDirectory\$Project"

            # Build installer
            $exitCode = (Start-Process -FilePath """$env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe""" -ArgumentList "/t:Installer /p:Configuration=Release ""$projectsDirectory\$Application\Deployment\Deployment.btdfproj"" /l:FileLogger,Microsoft.Build.Engine;logfile=$Application.msi.log" -PassThru -Wait).ExitCode

            # Check result
            if ($exitCode -eq 0) {
                Write-Information "MSI for $Application built succesfully"
            }
            else {
                Write-Error "MSI for $Application not built succesfully"
            }

            # Copy installer
            Copy-Item "$projectsDirectory\$Application\Deployment\bin\Release\*.msi" "$installersOutputDirectory"
        }
    }
}
