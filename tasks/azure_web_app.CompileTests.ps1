$repoRoot = git rev-parse --show-toplevel
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Branch coverage (tasks/azure_web_app.yml):
#   if DeployToSlotOrASE           -> "deploy to a slot" (entered), "with required parameters only" (not entered)
#   if RuntimeStack != ''          -> "Linux app with runtime settings" (entered)
#   if StartUpCommand != ''        -> "Linux app with runtime settings" (entered)
#   if AppSettings != ''           -> "with AppSettings and ConfigurationStrings" (entered)
#   if ConfigurationStrings != ''  -> "with AppSettings and ConfigurationStrings" (entered)

$validTestCases = @(
  @{
    Description = "with required parameters only"
    Parameters = @{
      AzureServiceConnection = "my-service-connection"
      AppType = "webApp"
      AppName = "my-web-app"
      Package = "drop/app.zip"
    }
    ExpectedYaml = @(
      "- task: AzureWebApp@1"
      "displayName: 'Deploy to Azure App Service: my-web-app'"
      "azureSubscription: my-service-connection"
      "appType: webApp"
      "appName: my-web-app"
      "package: drop/app.zip"
      "deployToSlotOrASE: false"
      "deploymentMethod: auto"
    )
  },
  @{
    Description = "deploy to a slot"
    Parameters = @{
      AzureServiceConnection = "my-service-connection"
      AppType = "webApp"
      AppName = "my-web-app"
      Package = "drop/app.zip"
      DeployToSlotOrASE = $true
      ResourceGroupName = "my-rg"
      SlotName = "preview"
    }
    ExpectedYaml = @(
      "deployToSlotOrASE: true"
      "resourceGroupName: my-rg"
      "slotName: preview"
    )
  },
  @{
    Description = "Linux app with runtime settings"
    Parameters = @{
      AzureServiceConnection = "my-service-connection"
      AppType = "webAppLinux"
      AppName = "my-web-app"
      Package = "drop/app.zip"
      RuntimeStack = "DOTNETCORE|8.0"
      StartUpCommand = "dotnet app.dll"
    }
    ExpectedYaml = @(
      "appType: webAppLinux"
      "runtimeStack: DOTNETCORE|8.0"
      "startUpCommand: dotnet app.dll"
    )
  },
  @{
    Description = "with AppSettings and ConfigurationStrings"
    Parameters = @{
      AzureServiceConnection = "my-service-connection"
      AppType = "webApp"
      AppName = "my-web-app"
      Package = "drop/app.zip"
      AppSettings = "-Key1 Value1"
      ConfigurationStrings = "-phpVersion 5.6"
      DeploymentMethod = "zipDeploy"
    }
    ExpectedYaml = @(
      "appSettings: -Key1 Value1"
      "configurationStrings: -phpVersion 5.6"
      "deploymentMethod: zipDeploy"
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "missing AzureServiceConnection"
    Parameters = @{
      AppType = "webApp"
      AppName = "my-web-app"
      Package = "drop/app.zip"
    }
    ErrorMessage = "A value for the 'AzureServiceConnection' parameter must be provided."
  },
  @{
    Description = "missing AppName"
    Parameters = @{
      AzureServiceConnection = "my-service-connection"
      AppType = "webApp"
      Package = "drop/app.zip"
    }
    ErrorMessage = "A value for the 'AppName' parameter must be provided."
  },
  @{
    Description = "missing Package"
    Parameters = @{
      AzureServiceConnection = "my-service-connection"
      AppType = "webApp"
      AppName = "my-web-app"
    }
    ErrorMessage = "A value for the 'Package' parameter must be provided."
  },
  @{
    Description = "AppType is not an allowed value"
    Parameters = @{
      AzureServiceConnection = "my-service-connection"
      AppType = "staticWebApp"
      AppName = "my-web-app"
      Package = "drop/app.zip"
    }
    ErrorMessage = "The 'AppType' parameter value 'staticWebApp' is not a valid value."
  },
  @{
    Description = "DeploymentMethod is not an allowed value"
    Parameters = @{
      AzureServiceConnection = "my-service-connection"
      AppType = "webApp"
      AppName = "my-web-app"
      Package = "drop/app.zip"
      DeploymentMethod = "ftp"
    }
    ErrorMessage = "The 'DeploymentMethod' parameter value 'ftp' is not a valid value."
  }
)

Run-Tests `
  -YamlPath "tasks/azure_web_app.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
