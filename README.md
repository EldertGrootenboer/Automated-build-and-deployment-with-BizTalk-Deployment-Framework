# Automated build and deployment with BizTalk Deployment Framework
[BizTalk Deployment Framework](https://biztalkdeployment.codeplex.com/) is one of those pearls for BizTalk developers, allowing complex BizTalk solutions to be deployed easily, having all our artifacts and dependencies together in one MSI. To make life even better for us, we can also automate the process of building and deploying these BTDF MSI's by using PowerShell. This especially comes in handy once we start having large projects with many BizTalk applications, where we would have to spend a lot of time manually running all these MSI's.

## Description
Using PowerShell we will make scripts which will handle all steps of the build and deployment process for us. This will make sure our applications are always deployed in the correct order, using the right versions, and with minimal effort. We have some general helper functions, which will help us clear log files, wait for user input, iterate through directories, etc. We assume you have are using some of the BTDF best practices for these scripts, where it comes to naming conventions and folder structure. Of course, in case anything differs in your environment, you can easily adjust the scripts to meet your requirements.

## Build
We will first create the PowerShell scripts which will help us build our applications. To be able to share these scripts along your different developers, where there might be some differences in the environments in how directories are set up, we will make use of a small csv file to hold our build environment settings.

```
Name;Value 
projectsBaseDirectory;F:\tfs 
installersOutputDirectory;F:\Deployment 
visualStudioDirectory;F:\Program Files (x86)\Microsoft Visual Studio 11.0
```

We will load these settings in our script and assign them to specific parameters.

```powershell
$settings = Import-Csv Settings_BuildEnvironment.csv 
foreach($setting in $settings) 
{ 
    # The directory where the BizTalk projects are stored 
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "projectsBaseDirectory") { $projectsBaseDirectory = $setting.'Name;Value'.Split(";")[1].Trim() } 
     
    # The directory where the MSI's should be saved to 
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "installersOutputDirectory") { $installersOutputDirectory = $setting.'Name;Value'.Split(";")[1].Trim() } 
     
    # Directory where Visual Studio resides 
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "visualStudioDirectory") { $visualStudioDirectory = $setting.'Name;Value'.Split(";")[1].Trim() } 
}
```

Now that we have our environment specific parameters set, we can create a function which will build our BizTalk application. We will assume you have several projects, which are in folders under a common directory ($projectsBaseDirectory), which is probably your source control root directory. Your application's directories should be under these project's directories. We will building the application by calling Visual Studio, and using the log to check if the build was successful.

```powershell
function BuildBizTalkApplication([string]$application, [string]$project) 
{ 
    # Set directory where the BizTalk projects for the current project are stored 
    $projectsDirectory = "$projectsBaseDirectory\$project" 
     
    # Clear log files and old installers 
    ClearLogFiles $application 
     
    # Build application 
    Write-Host "Building $application" -ForegroundColor Cyan 
    $exitCode = (Start-Process -FilePath "$visualStudioDirectory\Common7\IDE\devenv.exe" -ArgumentList """$projectsDirectory\$application\$application.sln"" /Build Release /Out $application.log" -PassThru -Wait).ExitCode 
 
    # Check result 
    if($exitCode -eq 0 -and (Select-String -Path "$application.log" -Pattern "0 failed" -Quiet) -eq "true") 
    { 
        Write-Host "$application built succesfully" -ForegroundColor Green 
    } 
    else 
    { 
        Write-Host "$application not built succesfully" -ForegroundColor Red 
        WaitForKeyPress 
    } 
}
```

Once the applications are built, we will also need to create MSI's for them, which is where the BTDF comes in. This can be done by calling MSBuild, and passing in the .btdfproj file. Finally we copy the MSI to a folder, so all our MSI's are together in one location and from there can be copied to the BizTalk server.

```powershell
function BuildBizTalkMsi([string]$application, [string]$project) 
{ 
    # Set directory where the BizTalk projects for the current project are stored 
    $projectsDirectory = "$projectsBaseDirectory\$project" 
     
    # Build installer 
    $exitCode = (Start-Process -FilePath """$env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe""" -ArgumentList "/t:Installer /p:Configuration=Release ""$projectsDirectory\$application\Deployment\Deployment.btdfproj"" /l:FileLogger,Microsoft.Build.Engine;logfile=$application.msi.log" -PassThru -Wait).ExitCode 
 
    # Check result 
    if($exitCode -eq 0) 
    { 
        Write-Host "MSI for $application built succesfully" -ForegroundColor Green 
    } 
    else 
    { 
        Write-Host "MSI for $application not built succesfully" -ForegroundColor Red 
        WaitForKeyPress 
    } 
 
    # Copy installer 
    copy "$projectsDirectory\$application\Deployment\bin\Release\*.msi" "$installersOutputDirectory" 
}
```

## Deployment
Once the MSI's have been created we can copy them to our BizTalk server, and start the deployment process. This process consists of 4 steps, starting with undeploying the old applications, uninstalling the old MSI's, installing the new MSI's and deploying the new applications. If your applications have dependencies on other applications, it's also important to undeploy and deploy them in the correct order. We will want to use one set of scripts for all our OTAP environments, so we will be using another csv file here to keep track of the environment specific settings, like directories and config files to use.

### Undeploy
We will start by loading the environment specific parameters.

```PowerShell
$settings = Import-Csv Settings_DeploymentEnvironment.csv 
foreach($setting in $settings) 
{ 
    # Program Files directory where application should be installed 
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "programFilesDirectory") { $programFilesDirectory = $setting.'Name;Value'.Split(";")[1].Trim() } 
     
    # Suffix as set in in the ProductName section of the BTDF project file. By default this is " for BizTalk". 
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "productNameSuffix") { $productNameSuffix = $setting.'Name;Value'.Split(";")[1].TrimEnd() } 
     
    # Indicator if we should deploy to the BizTalkMgmtDB database from this server. In multi-server environments this should be true on 1 server, and false on the others  
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "deployBizTalkMgmtDB") { $deployBizTalkMgmtDB = $setting.'Name;Value'.Split(";")[1].Trim() } 
}
```

Now we can write our function for undeploying. We will also be using MSBuild in conjuntion with BTDF here, by passing in the .btdfproj file location with the Undeploy switch. To do so, we will call the following function for each application to be undeployed. Remember to do the undeployment in the correct order.

```PowerShell
function UndeployBizTalkApplication([string]$application, [string]$version) 
{ 
    # Execute undeployment 
    $exitCode = (Start-Process -FilePath "$env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" -ArgumentList """$programFilesDirectory\$application$productNameSuffix\$version\Deployment\Deployment.btdfproj"" /t:Undeploy /p:DeployBizTalkMgmtDB=$deployBizTalkMgmtDB /p:Configuration=Server" -Wait -Passthru).ExitCode 
     
    if($exitCode -eq 0) 
    { 
        Write-Host "$application undeployed successfully" -ForegroundColor Green 
    } 
    else 
    { 
        Write-Host "$application not undeployed successfully" -ForegroundColor Red 
    } 
}
```

### Uninstall
Once all the applications for our project have been undeployed, we will uninstall the old MSI's. To do this, we will iterate through the MSI's in the specified directory, where we will pass in the directory with the last used installers.

```PowerShell
function UninstallBizTalkApplications($msiDirectory) 
{ 
    # Get MSI's to be installed 
    $files = GetMsiFiles $msiDirectory 
 
    # Loop through MSI files 
    foreach($file in $files) 
    { 
        UninstallBizTalkApplication $file 
    } 
}
```

This will call the uninstall command. We will assume our MSI's are named according to BTDF defaults, which is applicationname-version, so for example MyApplication-1.0.0.msi.

```PowerShell
function UninstallBizTalkApplication([System.IO.FileInfo]$fileInfo) 
{ 
    # Get application name 
    $applicationName = $fileInfo.BaseName.Split("-")[0] 
 
    # Set installer path 
    $msiPath = $fileInfo.FullName 
 
    # Uninstall application 
    $exitCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList "/x ""$msiPath"" /qn" -Wait -Passthru).ExitCode 
 
    # Check if uninstalling was successful 
    if($exitCode -eq 0) 
    { 
        Write-Host "$applicationName uninstalled successfully" -ForegroundColor Green 
    } 
    else 
    { 
        Write-Host "$applicationName not uninstalled successfully" -ForegroundColor Red 
    } 
}
```

### Install
The next step will be to install all the new MSI's we have just built. Here we will once again iterate through the specified directory, where we will now pass in the directory with the new installers.

```PowerShell
function InstallBizTalkApplications([string]$msiDirectory) 
{ 
    # Clear log files 
    ClearLogFiles $msiDirectory 
 
    # Get MSI's to be installed 
    $files = GetMsiFiles $msiDirectory 
 
    # Loop through MSI files 
    foreach($file in $files) 
    { 
        # Install application 
        InstallBizTalkApplication $file 
    } 
}
```

We will also have to load the environment specific parameters here.

```PowerShell
$settings = Import-Csv Settings_DeploymentEnvironment.csv 
foreach($setting in $settings) 
{ 
    # Program Files directory where application should be installed 
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "programFilesDirectory") { $programFilesDirectory = $setting.'Name;Value'.Split(";")[1].Trim() } 
     
    # Suffix as set in in the ProductName section of the BTDF project file. By default this is " for BizTalk". 
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "productNameSuffix") { $productNameSuffix = $setting.'Name;Value'.Split(";")[1].TrimEnd() } 
}
```

And now we can install the MSI. As mentioned before, we will assume our MSI's are named according to BTDF defaults (applicationname-version.msi).

```PowerShell
function InstallBizTalkApplication([System.IO.FileInfo]$fileInfo) 
{ 
    # Get application name and version 
    # We assume msi file name is in the format ApplicationName-Version 
    $application = $fileInfo.BaseName.Split("-")[0] 
    $version = $fileInfo.BaseName.Split("-")[1] 
 
    # Directory where MSI resides 
    $msiDirectory = $fileInfo.Directory 
 
    # Set log name 
    $logFileName = "$msiDirectory\$application.log" 
 
    # Set installer path 
    $msiPath = $fileInfo.FullName 
 
    # Install application 
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i ""$msiPath"" /passive /log ""$logFileName"" INSTALLDIR=""$programFilesDirectory\$application$productNameSuffix\$version""" -Wait -Passthru | Out-Null 
     
    # Check if installation was successful 
    if((Select-String -Path $logFileName -Pattern "success or error status: 0" -Quiet) -eq "true") 
    { 
        Write-Host "$application installed successfully" -ForegroundColor Green 
    } 
    else 
    { 
        Write-Host "$application not installed successfully" -ForegroundColor Red 
    } 
}
```

### Deploy
The last step is to deploy the applications we just installed. First we again have to load the environment specific parameters.

```PowerShell
$settings = Import-Csv Settings_DeploymentEnvironment.csv 
foreach($setting in $settings) 
{ 
    # Program Files directory where application should be installed 
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "programFilesDirectory") { $programFilesDirectory = $setting.'Name;Value'.Split(";")[1].Trim() } 
     
    # Suffix as set in in the ProductName section of the BTDF project file. By default this is " for BizTalk". 
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "productNameSuffix") { $productNameSuffix = $setting.'Name;Value'.Split(";")[1].TrimEnd() } 
     
    # Indicator if we should deploy to the BizTalkMgmtDB database from this server. In multi-server environments this should be true on 1 server, and false on the others  
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "deployBizTalkMgmtDB") { $deployBizTalkMgmtDB = $setting.'Name;Value'.Split(";")[1].Trim() } 
     
    # Name of the BTDF environment settings file for this environment.  
    if($setting.'Name;Value'.Split(";")[0].Trim() -eq "environmentSettingsFileName") { $environmentSettingsFileName = $setting.'Name;Value'.Split(";")[1].Trim() } 
}
```

Deploying is also done by using MSBuild with BTDF, by specifying the Deploy flag. For this we will be calling the following function for each application to be deployed, which of course should be done in the correct order.

```PowerShell
function DeployBizTalkApplication([string]$application, [string]$version) 
{ 
    # Set log file 
    $logFileName = "$programFilesDirectory\$application$productNameSuffix\$version\DeployResults\DeployResults.txt" 
 
    # Execute deployment 
    $exitCode = (Start-Process -FilePath "$env:windir\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe" -ArgumentList "/p:DeployBizTalkMgmtDB=$deployBizTalkMgmtDB;Configuration=Server;SkipUndeploy=true /target:Deploy /l:FileLogger,Microsoft.Build.Engine;logfile=""$programFilesDirectory\$application$productNameSuffix\$version\DeployResults\DeployResults.txt"" ""$programFilesDirectory\$application$productNameSuffix\$version\Deployment\Deployment.btdfproj"" /p:ENV_SETTINGS=""$programFilesDirectory\$application$productNameSuffix\$version\Deployment\EnvironmentSettings\$environmentSettingsFileName.xml""" -Wait -Passthru).ExitCode 
     
    # Check if deployment was successful 
    if($exitCode -eq 0 -and (Select-String -Path $logFileName -Pattern "0 Error(s)" -Quiet) -eq "true") 
    { 
        Write-Host "$application deployed successfully" -ForegroundColor Green 
    } 
    else 
    { 
        Write-Host "$application not deployed successfully" -ForegroundColor Red 
    } 
}
```

From the same location where we call this function, we will also do some additional checks. Sometimes you will want to import some registry files or execute a SQL script, which you might not want to include in your BTDF MSI for any reason. Also, once everything has been deployed, you might want to restart your host instances and IIS, which can also be handled here.

```PowerShell
function DeployBizTalkApplications([string[]]$applicationsInOrderOfDeployment, [string[]]$versions, [string]$scriptsDirectory) 
{ 
    # Check which restarts should be done 
    $resetIIS = CheckIfIISShouldBeReset 
    $restartHostInstances = CheckIfHostinstancesShouldBeRestarted 
 
    # Loop through applications to be deployed 
    for($index = 0; $index -lt $applicationsInOrderOfDeployment.Length; $index++) 
    { 
        # Deploy application 
        DeployBizTalkApplication $applicationsInOrderOfDeployment[$index] $versions[$index] 
    } 
 
    # Get SQL files to be executed 
    $sqlFiles = GetSQLFiles $scriptsDirectory 
 
    # Loop through SQL files 
    foreach($sqlFile in $sqlFiles) 
    { 
        # Execute SQL file 
        ExecuteSqlFile $sqlFile 
    } 
 
    # Get registry files to be imported 
    $registryFiles = GetRegistryFiles $scriptsDirectory 
 
    # Loop through registry files 
    foreach($registryFile in $registryFiles) 
    { 
        # Import registry file 
        ImportRegistryFile $registryFile 
    } 
 
    # Do restarts 
    if($resetIIS) 
    { 
        DoIISReset 
    } 
    if($restartHostInstances) 
    { 
        DoHostInstancesRestart  
    } 
}
```

## Bringing it all together
Finally, we have to stitch it all together. When you have downloaded the complete set of functions from this article, you can specify your build scripts as following, where you will only have to change the project name and applications to be built.

```PowerShell
# Project specific settings 
$projectName = "OrderSystem" 
$applications = @("Contoso.OrderSystem.Orders", "Contoso.OrderSystem.Invoices", "Contoso.OrderSystem.Payments") 
 
# Import custom functions 
. .\Functions_Build.ps1 
 
# Build the applications 
BuildAndCreateBizTalkInstallers $applications $projectName 
 
# Wait for user to exit 
WaitForKeyPress
```

As for deployment, all those steps can also be called from one single script as following. Once again, the only thing to change is the project specific settings.

```PowerShell
# Project specific settings 
$oldInstallersDirectory = "F:\tmp\R9" 
$newInstallersDirectory = "F:\tmp\R10" 
$newApplications = @("Contoso.OrderSystem.Orders", "Contoso.OrderSystem.Invoices", "Contoso.OrderSystem.Payments") 
$oldApplications = @("Contoso.OrderSystem.Payments", "Contoso.OrderSystem.Invoices", "Contoso.OrderSystem.Orders") 
$oldVersions = @("1.0.0", "1.0.0", "1.0.0") 
$newVersions = @("1.0.0", "1.0.1", "1.0.0") 
 
# Import custom functions 
. .\Functions_Deploy.ps1 
. .\Functions_Undeploy.ps1 
. .\Functions_Install.ps1 
. .\Functions_Uninstall.ps1 
 
# Undeploy the applications 
UndeployBizTalkApplications $oldApplications $oldVersions 
 
# Wait for user to continue 
WaitForKeyPress 
 
# Uninstall the applications 
UninstallBizTalkApplications $oldInstallersDirectory 
 
# Wait for user to continue 
WaitForKeyPress 
 
# Install the applications 
InstallBizTalkApplications $newInstallersDirectory 
 
# Wait for user to continue 
WaitForKeyPress 
 
# Deploy the applications 
DeployBizTalkApplications $newApplications $newVersions $newInstallersDirectory 
 
# Wait for user to exit 
WaitForKeyPress
```

As you can see, using these PowerShell scripts you can setup scripts for your build and deployment processes very quickly. And by automating all these steps, we will have to spend much less time on builds and deployments, as we will only have to start our scripts, and the rest just goes automatically.

# Support for -WhatIf

As a special bonus, all cmdlets support the PowerShell `-WhatIf` parameter, so you can check what will happen without actually executing code:

```PowerShell
> > . .\OrderSystemProject_FullDeploy.ps1 -WhatIf
What if: Performing the operation "Undeploy-BizTalkApplication" on target "Contoso.OrderSystem.Payments (1.0.0)".
What if: Performing the operation "Undeploy-BizTalkApplication" on target "Contoso.OrderSystem.Invoices (1.0.0)".
What if: Performing the operation "Undeploy-BizTalkApplication" on target "Contoso.OrderSystem.Orders (1.0.0)".
What if: Performing the operation "Deploy-BizTalkApplication" on target "Contoso.OrderSystem.Orders (1.1.0)".
What if: Performing the operation "Deploy-BizTalkApplication" on target "Contoso.OrderSystem.Invoices (1.1.0)".
What if: Performing the operation "Deploy-BizTalkApplication" on target "Contoso.OrderSystem.Payments (1.1.0)".
What if: Performing the operation "Restart-IIS" on target "localhost".
What if: Performing the operation "Restart-HostInstances" on target "localhost".
```

