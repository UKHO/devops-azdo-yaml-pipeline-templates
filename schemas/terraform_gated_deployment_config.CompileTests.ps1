# ============================================================================
# TEST: TERRAFORM GATED DEPLOYMENT CONFIG SCHEMA
# ============================================================================
# Validates only the properties consumed directly by jobs/terraform_gated_deployment.yml:
# AzDOEnvironmentName (duplicated from schemas/terraform_deploy_config.yml for clear
# standalone errors), RunMode, VerificationMode-required-when-RunMode-is-PlanVerifyApply,
# and the verification timeout fields.

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
  @{
    Description = "with RunMode set to PlanOnly"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanOnly"
      }
    }
  },
  @{
    Description = "with RunMode set to ApplyOnly"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "ApplyOnly"
      }
    }
  },
  @{
    Description = "with RunMode set to PlanVerifyApply and a valid VerificationMode"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
      }
    }
  },
  @{
    Description = "with valid VerificationTimeoutInMinutes and VerificationTimeoutBehaviour"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        VerificationTimeoutInMinutes = 30
        VerificationTimeoutBehaviour = "resume"
      }
    }
  },
  @{
    Description = "with VerificationTimeoutInMinutes at lower boundary (1)"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        VerificationTimeoutInMinutes = 1
      }
    }
  },
  @{
    Description = "with VerificationTimeoutInMinutes at upper boundary (43200)"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        VerificationTimeoutInMinutes = 43200
      }
    }
  }
)

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
        RunMode = "PlanOnly"
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
    Description = "missing RunMode in config"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: RunMode is not properly defined and is a required field. Must be a valid option (PlanVerifyApply, PlanOnly, ApplyOnly).'"
  },
  @{
    Description = "empty RunMode value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = ""
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: RunMode is not properly defined and is a required field. Must be a valid option (PlanVerifyApply, PlanOnly, ApplyOnly).'"
  },
  @{
    Description = "invalid RunMode value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "InvalidMode"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: RunMode must be a valid option (PlanVerifyApply, PlanOnly, ApplyOnly).'"
  },
  @{
    Description = "PlanVerifyApply without VerificationMode"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyApply"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: Must provide a valid VerificationMode option (VerifyOnDestroy, VerifyOnAny, VerifyDisabled).'"
  },
  @{
    Description = "PlanVerifyApply with invalid VerificationMode value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "InvalidMode"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: Must provide a valid VerificationMode option (VerifyOnDestroy, VerifyOnAny, VerifyDisabled).'"
  },
  @{
    Description = "invalid VerificationTimeoutBehaviour value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        VerificationTimeoutBehaviour = "invalid"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: VerificationTimeoutBehaviour must be either 'reject' or 'resume'.'"
  },
  @{
    Description = "VerificationTimeoutInMinutes below minimum (0)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        VerificationTimeoutInMinutes = 0
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: VerificationTimeoutInMinutes must be a number between 1 and 43200 (30 days).'"
  },
  @{
    Description = "VerificationTimeoutInMinutes above maximum (43201)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        VerificationTimeoutInMinutes = 43201
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: VerificationTimeoutInMinutes must be a number between 1 and 43200 (30 days).'"
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "schemas/terraform_gated_deployment_config.yml" `
  -TransformYamlFunction { param($yaml) return $yaml + @"
  - job:
    steps:
    - script: echo `"Hello World`"
"@ } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
