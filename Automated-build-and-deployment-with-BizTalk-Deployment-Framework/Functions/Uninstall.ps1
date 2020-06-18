# Import general helpers using dot operator
. "$PsScriptRoot\General.ps1"

# Uninstall application(s)
function Uninstall-BizTalkApplication {
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
                $files | Uninstall-BizTalkApplication
            }

            'ByFile' {

                if ($PSCmdlet.ShouldProcess($File.Name)) {
                    # Get application name
                    $applicationName = $File.BaseName.Split("-")[0]

                    # Set installer path
                    $msiPath = $File.FullName

                    # Uninstall application
                    $exitCode = (Start-Process -WindowStyle Hidden -FilePath "msiexec.exe" -ArgumentList "/x ""$msiPath"" /qn" -Wait -PassThru).ExitCode

                    # Check if uninstalling was successful
                    if ($exitCode -eq 0) {
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
