# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

$validTestCases = @(
  # INIT Command Tests
  @{
    Description = "init command without service connection (uses script)"
    Parameters = @{
      Command = "init"
    }
    ExpectedYaml = @(
      'terraform init'
      'displayName: Terraform init'
    )
  },
  @{
    Description = "init command without service connection and without backend (DisableBackend=true)"
    Parameters = @{
      Command = "init"
      DisableBackend = "true"
    }
    ExpectedYaml = @(
      'terraform init'
      '-backend=false'
    )
  },
  @{
    Description = "init command with full backend configuration"
    Parameters = @{
      Command = "init"
      BackendAzureServiceConnection = "my-service-connection"
      BackendAzureResourceGroupName = "my-rg"
      BackendAzureStorageAccountName = "mystgacct"
      BackendAzureContainerName = "tfstate"
      BackendAzureBlobName = "terraform.tfstate"
      EnvironmentAzureServiceConnection = "azure-subscription-connection"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: init"
      "provider: 'azurerm'"
      "backendServiceArm: my-service-connection"
      "backendAzureRmResourceGroupName: my-rg"
      "backendAzureRmStorageAccountName: mystgacct"
      "backendAzureRmContainerName: tfstate"
      "backendAzureRmKey: terraform.tfstate"
    )
  },
  @{
    Description = "init command with backend service connection only"
    Parameters = @{
      Command = "init"
      EnvironmentAzureServiceConnection = "my-service-connection"
      BackendAzureServiceConnection = "my-service-connection"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: init"
      "backendServiceArm: my-service-connection"
    )
  },

  # VALIDATE Command Test
  @{
    Description = "validate command"
    Parameters = @{
      Command = "validate"
      WorkingDirectory = "/path/to/terraform"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: validate"
      "provider: 'azurerm'"
      "workingDirectory: /path/to/terraform"
    )
  },

  # PLAN Command Tests
  @{
    Description = "plan command with environment service connection and command options"
    Parameters = @{
      Command = "plan"
      EnvironmentAzureServiceConnection = "azure-subscription-connection"
      CommandOptions = "-out=tfplan -input=false"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: plan"
      "environmentServiceNameAzureRM: azure-subscription-connection"
      "commandOptions: -out=tfplan -input=false"
    )
  },
<#  @{ # Cant get the TaskEnvironmentVariables to render in the compiled YAML, needs investigation
    Description = "plan command with task environment variables"
    Parameters = @{
      Command = "plan"
      EnvironmentAzureServiceConnection = "azure-subscription-connection"
      TaskEnvironmentVariables = @{
        TF_VAR_environment = "dev"
        TF_LOG = "DEBUG"
      }
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: plan"
      "environmentServiceNameAzureRM: azure-subscription-connection"
    )
  },#>

  # APPLY Command Tests
  @{
    Description = "apply command with environment service connection"
    Parameters = @{
      Command = "apply"
      EnvironmentAzureServiceConnection = "azure-subscription-connection"
      CommandOptions = "-input=false"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: apply"
      "environmentServiceNameAzureRM: azure-subscription-connection"
      "commandOptions: -input=false"
    )
  },
  @{
    Description = "apply command with working directory"
    Parameters = @{
      Command = "apply"
      WorkingDirectory = "`$(TerraformWorkingDirectory)"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: apply"
      "workingDirectory: `$(TerraformWorkingDirectory)"
    )
  },

  # OUTPUT Command Tests
  @{
    Description = "output command to console"
    Parameters = @{
      Command = "output"
      OutputTo = "console"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: output"
      "outputTo: console"
    )
  },
  @{
    Description = "output command to file with filename"
    Parameters = @{
      Command = "output"
      EnvironmentAzureServiceConnection = "azure-connection"
      OutputTo = "file"
      OutputFileName = "terraform-output.json"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: output"
      "outputTo: file"
      "fileName: terraform-output.json"
      "environmentServiceNameAzureRM: azure-connection"
    )
  },

  # SHOW Command Tests
  @{
    Description = "show command with default format"
    Parameters = @{
      Command = "show"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: show"
      "outputTo: console"
    )
  },
  @{
    Description = "show command with json output format"
    Parameters = @{
      Command = "show"
      OutputFormat = "json"
      OutputTo = "file"
      OutputFileName = "plan.json"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: show"
      "outputTo: file"
      "fileName: plan.json"
      "outputFormat: json"
    )
  },

  # DESTROY Command Test
  @{
    Description = "destroy command with environment service connection"
    Parameters = @{
      Command = "destroy"
      EnvironmentAzureServiceConnection = "azure-subscription-connection"
      CommandOptions = "-auto-approve"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: destroy"
      "environmentServiceNameAzureRM: azure-subscription-connection"
      "commandOptions: -auto-approve"
    )
  },

  # CUSTOM Command Test
  @{
    Description = "custom command"
    Parameters = @{
      Command = "custom"
      CustomCommand = "version"
    }
    ExpectedYaml = @(
      '- task: TerraformTask@5'
      "command: custom"
      "customCommand: version"
    )
  },

  # Task Naming and Retry Tests
  @{
    Description = "init with unique task slug"
    Parameters = @{
      Command = "init"
      TaskNameUniqueSlug = "primary"
      DisableBackend = "true"
    }
    ExpectedYaml = @(
      'name: TerraformTask_init_primary'
    )
  },
  @{
    Description = "plan command with retry count"
    Parameters = @{
      Command = "plan"
      RetryCountOnTaskFailure = 2
    }
    ExpectedYaml = @(
      'retryCountOnTaskFailure: 2'
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "with no parameters"
    Parameters = @{
    }
    ErrorMessage = "A value for the 'Command' parameter must be provided."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tasks/terraform.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
