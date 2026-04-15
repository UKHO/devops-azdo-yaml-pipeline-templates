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
    Description = "init command with full backend configuration"
    Parameters = @{
      Command = "init"
      CommandOptions = '-backend-config="key=terraform.tfstate" -backend-config="container_name=tfstate" -backend-config="storage_account_name=mysa" -backend-config="resource_group_name=my-rg"'
      ServiceConnection = "AzureRMServiceConnection"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      "terraform init"
      '-backend-config="resource_group_name=my-rg"'
      '-backend-config="storage_account_name=mysa"'
      '-backend-config="container_name=tfstate"'
      '-backend-config="key=terraform.tfstate"'
      '-backend-config="use_azuread_auth=true"'
    )
  },
  @{
    Description = "init command with backend disabled"
    Parameters = @{
      Command = "init"
      CommandOptions = '-backend=false'
      ServiceConnection = "AzureRMServiceConnection"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      "terraform init -backend=false  '"
    )
  },
  # PLAN Command Tests
  @{
    Description = "plan command and command options"
    Parameters = @{
      Command = "plan"
      CommandOptions = "-out=tfplan `$(VariableFilesCommandOption) -input=false"
      ServiceConnection = "AzureRMServiceConnection"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      "terraform plan"
      "-out=tfplan `$(VariableFilesCommandOption) -input=false"
    )
  },
  # APPLY Command Tests
  @{
    Description = "apply command"
    Parameters = @{
      Command = "apply"
      CommandOptions = '$(VariableFilesCommandOption) -input=false'
      ServiceConnection = "AzureRMServiceConnection"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      "terraform apply"
      '$(VariableFilesCommandOption) -input=false'
    )
  },
  # OUTPUT Command Tests
  @{
    Description = "output command to console"
    Parameters = @{
      Command = "output"
      ServiceConnection = "AzureRMServiceConnection"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      "terraform output"
    )
  },
  @{
    Description = "output command to file with SaveOutputsToFile true"
    Parameters = @{
      Command = "output"
      SaveOutputsToFile = $true
      ServiceConnection = "AzureRMServiceConnection"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      "terraform output"
      "> terraform-output.json"
    )
  },
  # CUSTOM Command Test
  @{
    Description = "custom command"
    Parameters = @{
      Command = "custom"
      CustomCommand = "version"
      ServiceConnection = "AzureRMServiceConnection"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      "terraform version"
    )
  },
  #
  # Task Naming and Retry Tests
  @{
    Description = "command with task environment variables"
    Parameters = @{
      ServiceConnection = "AzureRMServiceConnection"
      Command = "init"
      TaskEnvironmentVariables = @{
        TF_VAR_environment = "dev"
        TF_LOG = "DEBUG"
      }
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      "TF_VAR_environment: dev"
      "TF_LOG: DEBUG"
    )
  },
  @{
    Description = "command with correct displayName"
    Parameters = @{
      ServiceConnection = "AzureRMServiceConnection"
      Command = "init"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      'displayName: Terraform init'
    )
  },
  @{
    Description = "command with condition"
    Parameters = @{
      ServiceConnection = "AzureRMServiceConnection"
      Command = "init"
      Condition = "failure()"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      'condition: failure()'
    )
  },
  @{
    Description = "command with unique task slug"
    Parameters = @{
      ServiceConnection = "AzureRMServiceConnection"
      Command = "init"
      TaskNameUniqueSlug = "primary"
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      'name: TerraformTask_init_primary'
    )
  },
  @{
    Description = "command with retry count"
    Parameters = @{
      ServiceConnection = "AzureRMServiceConnection"
      Command = "init"
      RetryCountOnTaskFailure = 2
    }
    ExpectedYaml = @(
      '- task: AzureCLI@2'
      'azureSubscription: AzureRMServiceConnection'
      'retryCountOnTaskFailure: 2'
    )
  }
)

$invalidTestCases = @(
  @{
    Description = "with no parameters"
    Parameters = @{
      ServiceConnection = "AzureRMServiceConnection"
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
