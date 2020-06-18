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

Now that we have our environment specific parameters set, we can create a function which will build our BizTalk application. We will assume you have several projects, which are in folders under a common directory ($projectsBaseDirectory), which is probably your source control root directory. Your application's directories should be under these project's directories. We will building the application by calling Visual Studio, and using the log to check if the build was successful.

```powershell
$projectName = 'OrderSystem'
$applications = 'Contoso.OrderSystem.Orders'

Build-BizTalkApplication -Application $application -Project $projectName
```

Once the applications are built, we will also need to create MSI's for them, which is where the BTDF comes in. This can be done by calling MSBuild, and passing in the .btdfproj file. Finally we copy the MSI to a folder, so all our MSI's are together in one location and from there can be copied to the BizTalk server.

```powershell
Build-BizTalkMsi -Application $application -Project $projectName
```

## Deployment
Once the MSI's have been created we can copy them to our BizTalk server, and start the deployment process. This process consists of 4 steps, starting with undeploying the old applications, uninstalling the old MSI's, installing the new MSI's and deploying the new applications. If your applications have dependencies on other applications, it's also important to undeploy and deploy them in the correct order. We will want to use one set of scripts for all our OTAP environments, so we will be using another csv file here to keep track of the environment specific settings, like directories and config files to use.

```powershell

# Project specific settings
$oldInstallersDirectory = $PsScriptRoot
$newInstallersDirectory = $PsScriptRoot
$newApplications = @('Contoso.OrderSystem.Orders', 'Contoso.OrderSystem.Invoices', 'Contoso.OrderSystem.Payments')
$oldApplications = @('Contoso.OrderSystem.Payments', 'Contoso.OrderSystem.Invoices', 'Contoso.OrderSystem.Orders')
$oldVersions = @('1.0.0', '1.0.0', '1.0.0')
$newVersions = @('1.1.0', '1.1.0', '1.1.0')

# Undeploy the applications
Undeploy-BizTalkApplication -ApplicationsInOrderOfUndeployment $oldApplications -Versions $oldVersions

# Uninstall the applications
Uninstall-BizTalkApplication -Path $oldInstallersDirectory

# Install the applications
Install-BizTalkApplication -Path $newInstallersDirectory

# Deploy the applications
Deploy-BizTalkApplication -ApplicationsInOrderOfDeployment $newApplications -Versions $newVersions -ScriptsDirectory $newInstallersDirectory
```

As you can see, using these PowerShell scripts you can setup scripts for your build and deployment processes very quickly. And by automating all these steps, we will have to spend much less time on builds and deployments, as we will only have to start our scripts, and the rest just goes automatically.
