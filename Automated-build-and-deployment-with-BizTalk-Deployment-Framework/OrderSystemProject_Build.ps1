[CmdletBinding(SupportsShouldProcess)]
param()

# Project specific settings
$projectName = 'OrderSystem'
$applications = @('Contoso.OrderSystem.Orders', 'Contoso.OrderSystem.Invoices', 'Contoso.OrderSystem.Payments')

# Import custom functions
. "$PsScriptRoot\Functions\Build.ps1"

# Build the applications
$applications | Build-BizTalkInstaller -Project $projectName
