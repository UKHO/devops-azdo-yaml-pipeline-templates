# ============================================================================
# TEST: Terraform Destroy Job Template
# ============================================================================

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# Valid test cases with different parameter combinations
$validTestCases = @(
  @{
    Description = "Plan mode - basic"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "displayName: Plan 'TerraformArtifact'"
      "TerraformDestroyPlan_TerraformArtifact"
      "terraform plan -destroy"
    )
  },
  @{
    Description = "Destroy mode - basic"
    Parameters = @{
      TerraformDestroyMode = "Destroy"
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "displayName: Destroy 'TerraformArtifact'"
      "TerraformDestroyDestroy_TerraformArtifact"
      "terraform apply -destroy"
      "-auto-approve"
    )
  },
  @{
    Description = "Destroy mode with ConfigSources"
    Parameters = @{
      TerraformDestroyMode = "Destroy"
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        ConfigSources = @(
          @{
            Type = "KeyVault"
            Name = "dev-vault"
            ServiceConnection = "Azure-Dev-SC"
            SecretsFilter = "terraform-*"
          }
        )
      }
    }
    ExpectedYAML = @(
      "AzureKeyVault"
      "dev-vault"
      "Azure-Dev-SC"
    )
  },
  @{
    Description = "Destroy mode with Azure service connection"
    Parameters = @{
      TerraformDestroyMode = "Destroy"
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        AzureServiceConnection = "MyServiceConnection"
      }
    }
    ExpectedYAML = @(
      "azureSubscription: MyServiceConnection"
      "use_azuread_auth=true"
    )
  },
  @{
    Description = "Destroy mode with custom artifact name"
    Parameters = @{
      TerraformDestroyMode = "Destroy"
      TerraformArtifactName = "DestroyArtifact"
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "TerraformDestroyDestroy_DestroyArtifact"
      "displayName: Destroy 'DestroyArtifact'"
      "artifactName: DestroyArtifact"
    )
  },
  @{
    Description = "Condition is applied to the job"
    Parameters = @{
      Condition = "and(succeeded(), eq(variables.IsManual, 'true'))"
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "condition: and(succeeded(), eq(variables.IsManual, 'true'))"
    )
  },
  @{
    Description = "DependsOn is applied to the job"
    Parameters = @{
      DependsOn = @("PreviousJob")
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "dependsOn:*PreviousJob"
    )
  },
  @{
    Description = "Pool is applied to the job"
    Parameters = @{
      Pool = "Custom-Agent-Pool"
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "pool:*name: Custom-Agent-Pool"
    )
  },
  @{
    Description = "TerraformVersion is passed to the installer"
    Parameters = @{
      TerraformVersion = "1.6.0"
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ExpectedYAML = @(
      "inputs:*TerraformVersion:* 1.6.0"
    )
  }
)

# Invalid test cases
$invalidTestCases = @(
  @{
    Description = "ERROR: missing EnvironmentName parameter"
    Parameters = @{
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ErrorMessage = "A value for the 'EnvironmentName' parameter must be provided."
  },
  @{
    Description = "ERROR: missing TerraformDestroyConfig parameter"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
    }
    ErrorMessage = "A value for the 'TerraformDestroyConfig' parameter must be provided."
  },
  @{
    Description = "ERROR: KeyVaultConfig is not supported"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        KeyVaultConfig = @{
          ServiceConnection = "legacy"
          Name = "legacy"
          SecretsFilter = "*"
        }
      }
    }
    ErrorMessage = "KeyVaultConfig is deprecated and not supported for destroy workflows"
  }
)

# PreviousJob is appended so that cases can set DependsOn to an existing job
Run-Tests `
  -YamlPath "jobs/terraform_destroy.yml" `
  -TransformYamlFunction { param($yaml) return ($yaml -replace 'AzDOPipelineTemplates', 'self') + "`n  - job: PreviousJob`n    steps:`n      - script: echo PreviousJob`n" } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

