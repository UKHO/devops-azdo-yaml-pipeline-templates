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
        Description = "init command"
        Parameters = @{
            Command = "init"
        }
        ExpectedYaml = @(
            'terraform init'
        )
    },
    @{
        Description = "init command without backend"
        Parameters = @{
            Command = "init"
            CommandOptions = "-backend=false"
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
            CommandOptions = '-backend-config="key=terraform.tfstate" -backend-config="container_name=tfstate" -backend-config="storage_account_name=mysa" -backend-config="resource_group_name=my-rg"'
        }
        ExpectedYaml = @(
            "terraform init"
            '-backend-config="resource_group_name=my-rg"'
            '-backend-config="storage_account_name=mysa"'
            '-backend-config="container_name=tfstate"'
            '-backend-config="key=terraform.tfstate"'
        )
    },
    # VALIDATE Command Test
    @{
        Description = "validate command"
        Parameters = @{
            Command = "validate"
        }
        ExpectedYaml = @(
            "terraform validate"
        )
    },
    @{
        Description = "validate command with command options"
        Parameters = @{
            Command = "validate"
            CommandOptions = "-no-color"
        }
        ExpectedYaml = @(
            "terraform validate"
            "-no-color"
        )
    },
    # PLAN Command Tests
    @{
        Description = "plan command and command options"
        Parameters = @{
            Command = "plan"
            CommandOptions = "-out=tfplan `$(VariableFilesCommandOption) -input=false"
        }
        ExpectedYaml = @(
            "terraform plan"
            "-out=tfplan `$(VariableFilesCommandOption) -input=false"
        )
    },
    @{
        Description = "plan command with CommandOptions containing spaces and special characters"
        Parameters = @{
            Command = "plan"
            CommandOptions = '-var="my_var=value with spaces" -var-file="path/to/file.tfvars"'
        }
        ExpectedYaml = @(
            "terraform plan"
            '-var="my_var=value with spaces" -var-file="path/to/file.tfvars"'
        )
    },
    # APPLY Command Tests
    @{
        Description = "apply command"
        Parameters = @{
            Command = "apply"
            CommandOptions = '$(VariableFilesCommandOption) -input=false'
        }
        ExpectedYaml = @(
            "terraform apply"
            '$(VariableFilesCommandOption) -input=false'
        )
    },
    @{
        Description = "apply command with quoted CommandOptions"
        Parameters = @{
            Command = "apply"
            CommandOptions = '"-var=environment=prod" "-var=region=us-east-1"'
        }
        ExpectedYaml = @(
            "terraform apply"
            '"-var=environment=prod" "-var=region=us-east-1"'
        )
    },
    # OUTPUT Command Tests
    @{
        Description = "output command to console"
        Parameters = @{
            Command = "output"
        }
        ExpectedYaml = @(
            "terraform output"
        )
    },
    @{
        Description = "output command to console with SaveOutputsToFile false"
        Parameters = @{
            Command = "output"
            SaveCommandConsoleOutputToFile = $false
        }
        ExpectedYaml = @(
            "terraform output"
        )
    },
    @{
        Description = "output command to file with SaveOutputsToFile true"
        Parameters = @{
            Command = "output"
            SaveCommandConsoleOutputToFile = $true
            CommandConsoleOutputFileName = "terraform-output.json"
        }
        ExpectedYaml = @(
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
        }
        ExpectedYaml = @(
            "terraform version"
        )
    },
    #
    # Task Naming and Retry Tests
    @{
        Description = "command with task environment variables"
        Parameters = @{
            Command = "init"
            TaskEnvironmentVariables = @{
                TF_VAR_environment = "dev"
                TF_LOG = "DEBUG"
            }
        }
        ExpectedYaml = @(
            "TF_VAR_environment: dev"
            "TF_LOG: DEBUG"
        )
    },
    @{
        Description = "command with correct displayName"
        Parameters = @{
            Command = "init"
        }
        ExpectedYaml = @(
            'displayName: Terraform init'
        )
    },
    @{
        Description = "command with condition"
        Parameters = @{
            Command = "init"
            Condition = "failure()"
        }
        ExpectedYaml = @(
            'condition: failure()'
        )
    },
    @{
        Description = "command with unique task slug"
        Parameters = @{
            Command = "init"
            TaskNameUniqueSlug = "primary"
        }
        ExpectedYaml = @(
            'name: TerraformTask_init_primary'
        )
    },
    @{
        Description = "command with retry count"
        Parameters = @{
            Command = "init"
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
    },
    @{
        Description = "custom command with missing custom command"
        Parameters = @{
            Command = "custom"
        }
        ErrorMessage = "The 'CustomCommand' parameter is required when 'Command' is 'custom'."
    },
    @{
        Description = "custom command with empty custom command"
        Parameters = @{
            Command = "custom"
            CustomCommand = ""
        }
        ErrorMessage = "The 'CustomCommand' parameter is not a valid String."
    },
    @{
        Description = "custom command with missing custom command"
        Parameters = @{
            Command = "plan"
            SaveCommandConsoleOutputToFile = "true"
        }
        ErrorMessage = "The 'CommandConsoleOutputFileName' parameter is required when 'SaveCommandConsoleOutputToFile' is true."
    },
    @{
        Description = "custom command with missing custom command"
        Parameters = @{
            Command = "plan"
            CommandConsoleOutputFileName = "file"
        }
        ErrorMessage = "The 'SaveCommandConsoleOutputToFile' parameter is required when 'CommandConsoleOutputFileName' is not empty."
    }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tasks/terraform.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
