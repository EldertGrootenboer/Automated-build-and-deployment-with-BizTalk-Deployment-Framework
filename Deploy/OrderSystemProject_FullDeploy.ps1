[CmdletBinding(SupportsShouldProcess)]
param()

# Project specific settings
$oldInstallersDirectory = $PsScriptRoot
$newInstallersDirectory = $PsScriptRoot
$newApplications = @('Contoso.OrderSystem.Orders', 'Contoso.OrderSystem.Invoices', 'Contoso.OrderSystem.Payments')
$oldApplications = @('Contoso.OrderSystem.Payments', 'Contoso.OrderSystem.Invoices', 'Contoso.OrderSystem.Orders')
$oldVersions = @('1.0.0', '1.0.0', '1.0.0')
$newVersions = @('1.1.0', '1.1.0', '1.1.0')

# Import custom functions
. "$PsScriptRoot\Functions\Deploy.ps1"
. "$PsScriptRoot\Functions\Undeploy.ps1"
. "$PsScriptRoot\Functions\Install.ps1"
. "$PsScriptRoot\Functions\Uninstall.ps1"

# Undeploy the applications
Undeploy-BizTalkApplication -ApplicationsInOrderOfUndeployment $oldApplications -Versions $oldVersions

# Uninstall the applications
Uninstall-BizTalkApplication -Path $oldInstallersDirectory

# Install the applications
Install-BizTalkApplication -Path $newInstallersDirectory

# Deploy the applications
Deploy-BizTalkApplication -ApplicationsInOrderOfDeployment $newApplications -Versions $newVersions -ScriptsDirectory $newInstallersDirectory
