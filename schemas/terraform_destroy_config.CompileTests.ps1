# ============================================================================
# TEST: TERRAFORM DESTROY CONFIG SCHEMA
# ============================================================================

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

$validTestCases = @(
  @{
    Description = "required parameters only"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
      }
    }
  },
  @{
    Description = "with ConfigSources"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "prod-environment"
        ConfigSources = @(
          @{
            Type = "KeyVault"
            Name = "prod-vault"
            ServiceConnection = "prod-sc"
            SecretsFilter = "*"
          }
        )
      }
    }
  },
  @{
    Description = "with all optional fields"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        AzureServiceConnection = "my-service-connection"
        BackendConfig = @{
          resource_group_name = "my-rg"
          key = "dev.tfstate"
        }
        EnvironmentVariableMappings = @{
          TF_LOG = "INFO"
        }
        VariableFiles = @("vars/common.tfvars", "vars/dev.tfvars")
      }
    }
  },
  @{
    Description = "with empty BackendConfig, EnvironmentVariableMappings and VariableFiles"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        BackendConfig = @{ }
        EnvironmentVariableMappings = @{ }
        VariableFiles = @()
      }
    }
  }
)

$invalidTestCases = @(
  @{
    Description = "missing EnvironmentName parameter"
    Parameters = @{
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanOnly"
      }
    }
    ErrorMessage = "A value for the 'EnvironmentName' parameter must be provided."
  },
  @{
    Description = "missing TerraformDestroyConfig parameter"
    Parameters = @{
      EnvironmentName = "dev"
    }
    ErrorMessage = "A value for the 'TerraformDestroyConfig' parameter must be provided."
  },
  @{
    Description = "KeyVaultConfig is deprecated and not supported"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        KeyVaultConfig = @{
          ServiceConnection = "legacy"
          Name = "kv"
          SecretsFilter = "*"
        }
      }
    }
    ErrorMessage = "KeyVaultConfig is deprecated and not supported for destroy workflows. Use ConfigSources instead."
  },
  @{
    Description = "VerificationMode is not supported"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        VerificationMode = "VerifyOnAny"
      }
    }
    ErrorMessage = "VerificationMode is not supported for destroy workflows. Use RunMode 'PlanVerifyDestroy' for gated destroy."
  },
  @{
    Description = "missing AzDOEnvironmentName in TerraformDestroyConfig"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzureServiceConnection = "my-service-connection"
      }
    }
    ErrorMessage = "'dev' environment error: AzDOEnvironmentName is not properly defined and is a required field."
  },
  @{
    Description = "empty AzDOEnvironmentName in TerraformDestroyConfig"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = ""
      }
    }
    ErrorMessage = "'dev' environment error: AzDOEnvironmentName is not properly defined and is a required field."
  },
  @{
    Description = "empty AzureServiceConnection value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        AzureServiceConnection = ""
      }
    }
    ErrorMessage = "'dev' environment error: AzureServiceConnection is not properly defined."
  },
  @{
    Description = "BackendConfig is not an object"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        BackendConfig = "not-an-object"
      }
    }
    ErrorMessage = "'dev' environment error: BackendConfig is not correct. Must be an object of key/value pairs."
  },
  @{
    Description = "BackendConfig with empty key value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        BackendConfig = @{
          "resource_group_name" = ""
          "storage_account_name" = "mysa"
        }
      }
    }
    ErrorMessage = "'dev' environment error: BackendConfig is not correct. Must be an object of key/value pairs."
  },
  @{
    Description = "BackendConfig with empty key name"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        BackendConfig = @{
          "" = "mysa"
        }
      }
    }
    ErrorMessage = "'dev' environment error: BackendConfig is not correct. Must be an object of key/value pairs."
  },
  @{
    Description = "EnvironmentVariableMappings is not an object"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        EnvironmentVariableMappings = "not-an-object"
      }
    }
    ErrorMessage = "'dev' environment error: EnvironmentVariableMappings is not correct. Must be an object of key/value pairs."
  },
  @{
    Description = "EnvironmentVariableMappings with empty value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        EnvironmentVariableMappings = @{
          "ARM_SUBSCRIPTION_ID" = ""
          "ARM_TENANT_ID" = "tenant-id"
        }
      }
    }
    ErrorMessage = "'dev' environment error: EnvironmentVariableMappings is not correct. Key: 'ARM_SUBSCRIPTION_ID'. Value: ''. Must be an object of key/value pairs."
  },
  @{
    Description = "EnvironmentVariableMappings with empty key"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        EnvironmentVariableMappings = @{
          "" = "value"
        }
      }
    }
    ErrorMessage = "'dev' environment error: EnvironmentVariableMappings is not correct. Key: ''. Value: 'value'. Must be an object of key/value pairs."
  },
  @{
    Description = "VariableFiles is not a list"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        VariableFiles = "not-a-list"
      }
    }
    ErrorMessage = "'dev' environment error: VariableFiles is not correct. Must be a list of string values."
  },
  @{
    Description = "VariableFiles contains non-string object"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        VariableFiles = @("vars/common.tfvars", @{ nested = "object" })
      }
    }
    ErrorMessage = "'dev' environment error: VariableFiles item"
  }
)

Run-Tests `
  -YamlPath "schemas/terraform_destroy_config.yml" `
  -TransformYamlFunction { param($yaml) return $yaml + @"
  - job:
    steps:
    - script: echo \"Hello World\"
"@ } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

