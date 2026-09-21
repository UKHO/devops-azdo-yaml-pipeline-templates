# ============================================================================
# TEST: Terraform Deploy Job Template
# ============================================================================
# Comprehensive test cases for terraform_deploy.yml template.

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
    Description = "Plan Mode - Basic"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "displayName: Plan 'TerraformArtifact'"
      "TerraformDeployPlan_TerraformArtifact"
    )
  },
  @{
    Description = "Apply Mode - Basic"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "displayName: Apply 'TerraformArtifact'"
      "TerraformDeployApply_TerraformArtifact"
    )
  },
  @{
    Description = "Plan with VerifyOnDestroy"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        VerificationMode = "VerifyOnDestroy"
      }
    }
    ExpectedYAML = @(
      "VerifyOnDestroy"
      "TerraformChangesCheck"
    )
  },
  @{
    Description = "Plan with VerifyOnAny"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        VerificationMode = "VerifyOnAny"
      }
    }
    ExpectedYAML = @(
      "VerifyOnAny"
      "TerraformChangesCheck"
    )
  },
  @{
    Description = "Plan with VerifyDisabled"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        VerificationMode = "VerifyDisabled"
      }
    }
    ExpectedYAML = @(
      "VerifyDisabled"
      "TerraformChangesCheck"
    )
  },
  @{
    Description = "Plan Without Verification"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "displayName: Terraform Plan"
    )
  },
  @{
    Description = "Apply with Single Output Variable"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        OutputVariables = @("resource_group_id")
      }
    }
    ExpectedYAML = @(
      "TerraformExportOutputsVariables"
      "terraform-output-variables.json"
    )
  },
  @{
    Description = "Apply with Multiple Output Variables"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        OutputVariables = @("resource_group_id", "app_service_url", "storage_account_name")
      }
    }
    ExpectedYAML = @(
      "TerraformExportOutputsVariables"
      "resource_group_id,app_service_url,storage_account_name"
    )
  },
  @{
    Description = "Apply Without Output Variables"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "displayName: Terraform Apply"
    )
  },
  @{
    Description = "Apply with Key Vault Configuration (All Three Properties)"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        KeyVaultConfig = @{
          ServiceConnection = "vault-service-connection"
          Name = "my-key-vault"
          SecretsFilter = "*"
        }
      }
    }
    ExpectedYAML = @(
      "AzureKeyVault"
      "vault-service-connection"
      "my-key-vault"
    )
  },
  @{
    Description = "Apply with Backend Configuration"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        BackendConfig = @{
          resource_group_name = "my-rg"
          storage_account_name = "mysa"
          container_name = "tfstate"
          key = "dev.tfstate"
        }
      }
    }
    ExpectedYAML = @(
      "-backend-config="
      "resource_group_name=my-rg"
    )
  },
  @{
    Description = "Apply with Empty Backend Configuration"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        BackendConfig = @{ }
      }
    }
    ExpectedYAML = @(
      "BackendConfigCommandOption*value: ''"
    )
  },
  @{
    Description = "Apply with Backend Configuration - Multiple Properties"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        BackendConfig = @{
          ConfigKey = "ConfigValue"
        }
      }
    }
    ExpectedYAML = @(
      "-backend-config=`"ConfigKey=ConfigValue`""
    )
  },
  @{
    Description = "Apply with Environment Variables"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        EnvironmentVariableMappings = @{
          TF_VAR_environment = "production"
          TF_VAR_location = "westus"
          TF_LOG = "INFO"
        }
      }
    }
    ExpectedYAML = @(
      "TF_VAR_environment: production"
      "TF_LOG: INFO"
    )
  },
  @{
    Description = "Apply with Single Variable File"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        VariableFiles = @("config/common.tfvars")
      }
    }
    ExpectedYAML = @(
      "-var-file="
      "config/common.tfvars"
    )
  },
  @{
    Description = "Apply with Multiple Variable Files"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        VariableFiles = @("config/common.tfvars", "config/production.tfvars", "config/secrets.tfvars")
      }
    }
    ExpectedYAML = @(
      "-var-file="
      "config/common.tfvars"
      "config/production.tfvars"
      "config/secrets.tfvars"
    )
  },
  @{
    Description = "Apply with Variable Group"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        JobsVariableMappings = @(
          @{ group = "ProductionVariables" }
        )
      }
    }
    ExpectedYAML = @(
      "group: ProductionVariables"
    )
  },
  @{
    Description = "Apply with Multiple Variable Groups"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        JobsVariableMappings = @(
          @{ group = "CommonVariables" }
          @{ group = "EnvironmentVariables" }
          @{ group = "SecurityVariables" }
        )
      }
    }
    ExpectedYAML = @(
      "group: CommonVariables"
      "group: EnvironmentVariables"
      "group: SecurityVariables"
    )
  },
  @{
    Description = "Apply with Azure Service Connection"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        AzureServiceConnection = "MyServiceConnection"
      }
    }
    ExpectedYAML = @(
      "azureSubscription: MyServiceConnection"
    )
  },
  @{
    Description = "Apply with Specific Terraform Version"
    Parameters = @{
      TerraformDeployMode = "Apply"
      TerraformVersion = "1.6.0"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "inputs:*TerraformVersion:* 1.6.0"
    )
  },
  @{
    Description = "Apply with Different Terraform Version"
    Parameters = @{
      TerraformDeployMode = "Apply"
      TerraformVersion = "1.4.6"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "inputs:*TerraformVersion:* 1.4.6"
    )
  },
  @{
    Description = "Apply with Self Checkout"
    Parameters = @{
      TerraformDeployMode = "Apply"
      CheckoutAlias = "self"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "repository: self"
    )
  },
  @{
    Description = "Apply with Custom Condition"
    Parameters = @{
      TerraformDeployMode = "Apply"
      Condition = "and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "condition: and(succeeded()"
    )
  },
  @{
    Description = "Apply with Custom Artifact Name"
    Parameters = @{
      TerraformDeployMode = "Apply"
      TerraformArtifactName = "CustomArtifact"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "TerraformDeployApply_CustomArtifact"
      "displayName: Apply 'CustomArtifact'"
    )
  },
  @{
    Description = "Apply with Default Artifact Name"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "displayName: Apply 'TerraformArtifact'"
    )
  },
  @{
    Description = "Apply with Double ConfigSources entries"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        ConfigSources = @(
          @{
            Type = "KeyVault"
            Name = "dev-vault-1"
            ServiceConnection = "Azure-Dev-SC"
            SecretsFilter = "terraform-*"
          }
          @{
            Type = "KeyVault"
            Name = "dev-vault-2"
            ServiceConnection = "Azure-Dev-SC"
            SecretsFilter = "pipeline-*"
          }
        )
      }
    }
    ExpectedYAML = @(
      "AzureKeyVault"
      "Download secrets: dev-vault-1"
      "Azure-Dev-SC"
      "dev-vault-1"
      "dev-vault-2"
      "terraform-*"
      "pipeline-*"
    )
  }
)

# Invalid test cases
$invalidTestCases = @(
  @{
    Description = "ERROR: missing EnvironmentName parameter"
    Parameters = @{
    }
    ErrorMessage = "A value for the 'EnvironmentName' parameter must be provided."
  },
  @{
    Description = "ERROR: missing TerraformDeploymentConfig parameter"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
    }
    ErrorMessage = "A value for the 'TerraformDeploymentConfig' parameter must be provided."
  },
  @{
    Description = "ERROR: missing AzDOEnvironmentName in config"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
      TerraformDeploymentConfig = @{ }
    }
    ErrorMessage = "AzDOEnvironmentName is not properly defined and is a required field"
  },
  @{
    Description = "ERROR: invalid VerificationMode value"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        VerificationMode = "InvalidMode"
      }
    }
    ErrorMessage = "Unexpected value ''compile-tests-only' environment error: If provided, VerificationMode must be a valid option (VerifyOnDestroy, VerifyOnAny, VerifyDisabled).'"
  },
  @{
    Description = "ERROR: Partial Key Vault Configuration"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        KeyVaultConfig = @{
          ServiceConnection = "vault-service-connection"
        }
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: KeyVaultConfig.Name is required when any Key Vault configuration is provided.'*Unexpected value ''dev' environment error: KeyVaultConfig.SecretsFilter is required when any Key Vault configuration is provided.'"
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "jobs/terraform_deploy.yml" `
  -TransformYamlFunction { param($yaml) return $yaml -replace 'AzDOPipelineTemplates', 'self' } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
