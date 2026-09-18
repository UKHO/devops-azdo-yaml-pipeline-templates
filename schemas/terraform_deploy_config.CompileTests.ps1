# ============================================================================
# TEST: TERRAFORM DEPLOY CONFIG SCHEMA
# ============================================================================
# This test demonstrates how to write tests using the simple PowerShell framework.
# Validates only the properties consumed directly by jobs/terraform_deploy.yml.
#
# Note: VerificationMode's enum value IS validated here, because
# jobs/terraform_deploy.yml conditionally adds plan-verification steps when it is
# provided. However, whether VerificationMode is *required* (based on RunMode) is
# validated separately in schemas/terraform_gated_deployment_config.CompileTests.ps1,
# since RunMode is only consumed by jobs/terraform_gated_deployment.yml.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

# Valid test cases with different parameter combinations
$validTestCases = @(
  @{
    Description = "with required parameters only"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
      }
    }
  },
  @{
    Description = "with VerificationMode set to VerifyOnDestroy"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        VerificationMode = "VerifyOnDestroy"
      }
    }
  },
  @{
    Description = "with VerificationMode set to VerifyOnAny"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        VerificationMode = "VerifyOnAny"
      }
    }
  },
  @{
    Description = "with VerificationMode set to VerifyDisabled"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        VerificationMode = "VerifyDisabled"
      }
    }
  },
  @{
    Description = "with optional AzureServiceConnection parameter"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        AzureServiceConnection = "my-service-connection"
      }
    }
  },
  @{
    Description = "with complete KeyVaultConfig"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        KeyVaultConfig = @{
          ServiceConnection = "vault-service-connection"
          Name = "my-vault"
          SecretsFilter = "secret*"
        }
      }
    }
  },
  @{
    Description = "with complete ConfigSources for KeyVault"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        ConfigSources = @{
          Type = "KeyVault"
          ServiceConnection = "vault-service-connection"
          Name = "my-vault"
          SecretsFilter = "secret*"
        }
      }
    }
  },
  @{
    Description = "with BackendConfig as key/value pairs"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        BackendConfig = @{
          "resource_group_name" = "my-rg"
          "storage_account_name" = "mysa"
          "container_name" = "tfstate"
          "key" = "prod.tfstate"
        }
      }
    }
  },
  @{
    Description = "with EnvironmentVariableMappings as key/value pairs"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        EnvironmentVariableMappings = @{
          "ARM_SUBSCRIPTION_ID" = "subscription-id"
          "ARM_TENANT_ID" = "tenant-id"
          "ARM_CLIENT_ID" = "client-id"
        }
      }
    }
  },
  @{
    Description = "with VariableFiles as list of strings"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        VariableFiles = @("vars/common.tfvars", "vars/dev.tfvars")
      }
    }
  },
  @{
    Description = "with OutputVariables as list of strings"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        OutputVariables = @("resource_group_id", "storage_account_id")
      }
    }
  },
  @{
    Description = "with all optional parameters provided"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        VerificationMode = "VerifyOnAny"
        AzureServiceConnection = "prod-service-connection"
        KeyVaultConfig = @{
          ServiceConnection = "vault-service-connection"
          Name = "prod-vault"
          SecretsFilter = "prod/*"
        }
        BackendConfig = @{
          "resource_group_name" = "prod-rg"
          "storage_account_name" = "prodsa"
          "container_name" = "tfstate"
          "key" = "prod.tfstate"
        }
        EnvironmentVariableMappings = @{
          "ARM_SUBSCRIPTION_ID" = "prod-subscription"
          "ARM_ENVIRONMENT" = "AzurePublicCloud"
        }
        VariableFiles = @("vars/common.tfvars", "vars/prod.tfvars", "vars/prod-secrets.tfvars")
        OutputVariables = @("resource_id", "storage_id", "database_connection_string")
      }
    }
  }
)

# Invalid test cases
$invalidTestCases = @(
  @{
    Description = "missing EnvironmentName parameter"
    Parameters = @{
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
      }
    }
    ErrorMessage = "A value for the 'EnvironmentName' parameter must be provided."
  },
  @{
    Description = "missing TerraformDeploymentConfig parameter"
    Parameters = @{
      EnvironmentName = "dev"
    }
    ErrorMessage = "A value for the 'TerraformDeploymentConfig' parameter must be provided."
  },
  @{
    Description = "missing AzDOEnvironmentName in TerraformDeploymentConfig"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzureServiceConnection = "my-service-connection"
      }
    }
    ErrorMessage = "'dev' environment error: AzDOEnvironmentName is not properly defined and is a required field."
  },
  @{
    Description = "empty AzDOEnvironmentName in TerraformDeploymentConfig"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = ""
      }
    }
    ErrorMessage = "'dev' environment error: AzDOEnvironmentName is not properly defined and is a required field."
  },
  @{
    Description = "invalid VerificationMode value"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        VerificationMode = "InvalidMode"
      }
    }
    ErrorMessage = "'prod' environment error: If provided, VerificationMode must be a valid option (VerifyOnDestroy, VerifyOnAny, VerifyDisabled)."
  },
  @{
    Description = "empty VerificationMode value"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        VerificationMode = ""
      }
    }
    ErrorMessage = "'prod' environment error: If provided, VerificationMode must be a valid option (VerifyOnDestroy, VerifyOnAny, VerifyDisabled)."
  },
  @{
    Description = "empty AzureServiceConnection value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        AzureServiceConnection = ""
      }
    }
    ErrorMessage = "'dev' environment error: AzureServiceConnection is not properly defined."
  },
  @{
    Description = "KeyVaultConfig with only ServiceConnection (missing Name and SecretsFilter)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        KeyVaultConfig = @{
          ServiceConnection = "vault-service-connection"
        }
      }
    }
    ErrorMessage = "'dev' environment error: KeyVaultConfig.Name is required when any Key Vault configuration is provided."
  },
  @{
    Description = "KeyVaultConfig with only Name (missing ServiceConnection and SecretsFilter)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        KeyVaultConfig = @{
          Name = "my-vault"
        }
      }
    }
    ErrorMessage = "'dev' environment error: KeyVaultConfig.ServiceConnection is required when any Key Vault configuration is provided."
  },
  @{
    Description = "KeyVaultConfig with only SecretsFilter (missing ServiceConnection and Name)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        KeyVaultConfig = @{
          SecretsFilter = "secret*"
        }
      }
    }
    ErrorMessage = "'dev' environment error: KeyVaultConfig.ServiceConnection is required when any Key Vault configuration is provided."
  },
  @{
    Description = "KeyVaultConfig with empty ServiceConnection"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        KeyVaultConfig = @{
          ServiceConnection = ""
          Name = "my-vault"
          SecretsFilter = "secret*"
        }
      }
    }
    ErrorMessage = "'dev' environment error: KeyVaultConfig.ServiceConnection is required when any Key Vault configuration is provided."
  },
  @{
    Description = "KeyVaultConfig with empty Name"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        KeyVaultConfig = @{
          ServiceConnection = "vault-service-connection"
          Name = ""
          SecretsFilter = "secret*"
        }
      }
    }
    ErrorMessage = "'dev' environment error: KeyVaultConfig.Name is required when any Key Vault configuration is provided."
  },
  @{
    Description = "KeyVaultConfig with empty SecretsFilter"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        KeyVaultConfig = @{
          ServiceConnection = "vault-service-connection"
          Name = "my-vault"
          SecretsFilter = ""
        }
      }
    }
    ErrorMessage = "'dev' environment error: KeyVaultConfig.SecretsFilter is required when any Key Vault configuration is provided."
  },
  @{
    Description = "Mixing KeyVaultConfig and ConfigSources"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        KeyVaultConfig = @{
          ServiceConnection = "vault-service-connection"
          Name = "my-vault"
          SecretsFilter = ""
        }
        ConfigSources = @"
        - Type: KeyVault
          Name: second-vault
          ServiceConnection: vault-service-connection
"@
      }
    }
    ErrorMessage = "'dev' environment error: use either KeyVaultConfig (legacy) or ConfigSources (new), not both. Both parameters cannot coexist in the same configuration. See upgrade guide: docs/user-docs/upgrades/0.1.0-to-0.2.0-keyvaultconfig-to-configsources.md"
  },
  @{
    Description = "BackendConfig with empty key value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
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
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        BackendConfig = @{
          "" = "mysa"
        }
      }
    }
    ErrorMessage = "'dev' environment error: BackendConfig is not correct. Must be an object of key/value pairs."
  },
  @{
    Description = "EnvironmentVariableMappings with empty value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
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
      TerraformDeploymentConfig = @{
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
      TerraformDeploymentConfig = @{
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
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        VariableFiles = @("vars/common.tfvars", @{ nested = "object" })
      }
    }
    ErrorMessage = "'dev' environment error: VariableFiles item"
  },
  @{
    Description = "VariableFiles contains nested list"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        VariableFiles = @("vars/common.tfvars", @("nested", "list"))
      }
    }
    ErrorMessage = "'dev' environment error: VariableFiles item"
  },
  @{
    Description = "OutputVariables is not a list"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        OutputVariables = "not-a-list"
      }
    }
    ErrorMessage = "'dev' environment error: OutputVariables is not correct. Must be a list of string values."
  },
  @{
    Description = "OutputVariables contains non-string object"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        OutputVariables = @("resource_id", @{ nested = "object" })
      }
    }
    ErrorMessage = "'dev' environment error: OutputVariables item"
  },
  @{
    Description = "OutputVariables contains nested list"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        OutputVariables = @("resource_id", @("nested", "list"))
      }
    }
    ErrorMessage = "'dev' environment error: OutputVariables item"
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "schemas/terraform_deploy_config.yml" `
  -TransformYamlFunction { param($yaml) return $yaml + @"
  - job:
    steps:
    - script: echo `"Hello World`"
"@ } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
