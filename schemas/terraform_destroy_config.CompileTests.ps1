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
    Description = "required parameters only (PlanOnly)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanOnly"
      }
    }
  },
  @{
    Description = "required parameters only (DestroyOnly)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "DestroyOnly"
      }
    }
  },
  @{
    Description = "required parameters only (PlanVerifyDestroy)"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyDestroy"
      }
    }
  },
  @{
    Description = "with ConfigSources"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyDestroy"
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
    Description = "with valid VerificationTimeoutInMinutes and VerificationTimeoutBehaviour"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutInMinutes = 120
        VerificationTimeoutBehaviour = "resume"
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
    Description = "invalid RunMode value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "InvalidMode"
      }
    }
    ErrorMessage = "Must provide a valid RunMode option (PlanVerifyDestroy, PlanOnly, DestroyOnly)."
  },
  @{
    Description = "KeyVaultConfig is deprecated and not supported"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "DestroyOnly"
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
        RunMode = "PlanVerifyDestroy"
        VerificationMode = "VerifyOnAny"
      }
    }
    ErrorMessage = "VerificationMode is not supported for destroy workflows. Use RunMode 'PlanVerifyDestroy' for gated destroy."
  },
  @{
    Description = "invalid VerificationTimeoutBehaviour value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutBehaviour = "invalid"
      }
    }
    ErrorMessage = "VerificationTimeoutBehaviour must be either 'reject' or 'resume'."
  },
  @{
    Description = "VerificationTimeoutInMinutes below minimum range"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutInMinutes = 0
      }
    }
    ErrorMessage = "VerificationTimeoutInMinutes must be a number between 1 and 43200 (30 days)."
  },
  @{
    Description = "VerificationTimeoutInMinutes above maximum range"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutInMinutes = 43201
      }
    }
    ErrorMessage = "VerificationTimeoutInMinutes must be a number between 1 and 43200 (30 days)."
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

