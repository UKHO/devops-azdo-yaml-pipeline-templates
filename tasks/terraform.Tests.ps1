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

    # OUTPUT Command Tests
    @{
      Description = "output command to console"
      Parameters = @{
        Command = "output"
        OutputTo = "console"
      }
      ExpectedYaml = @(
        "terraform output"
        "outputTo: console"
      )
    },
    @{
      Description = "output command to file with filename"
      Parameters = @{
        Command = "output"
        OutputTo = "file"
        OutputFileName = "terraform-output.json"
      }
      ExpectedYaml = @(
        "terraform output"
        "outputTo: file"
        "fileName: terraform-output.json"
      )
    },
  #
  #  # SHOW Command Tests
  #  @{
  #    Description = "show command with default format"
  #    Parameters = @{
  #      Command = "show"
  #    }
  #    ExpectedYaml = @(
  #      "command: show"
  #      "outputTo: console"
  #    )
  #  },
  #  @{
  #    Description = "show command with json output format"
  #    Parameters = @{
  #      Command = "show"
  #      OutputFormat = "json"
  #      OutputTo = "file"
  #      OutputFileName = "plan.json"
  #    }
  #    ExpectedYaml = @(
  #      "command: show"
  #      "outputTo: file"
  #      "fileName: plan.json"
  #      "outputFormat: json"
  #    )
  #  },
  #
  #  # DESTROY Command Test
  #  @{
  #    Description = "destroy command with environment service connection"
  #    Parameters = @{
  #      Command = "destroy"
  #      CommandOptions = "-auto-approve"
  #    }
  #    ExpectedYaml = @(
  #      "command: destroy"
  #      "commandOptions: -auto-approve"
  #    )
  #  },
  #
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
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tasks/terraform.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
