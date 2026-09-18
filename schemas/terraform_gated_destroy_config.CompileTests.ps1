# ============================================================================
# TEST: TERRAFORM GATED DESTROY CONFIG SCHEMA
# ============================================================================
# Validates only the properties consumed directly by jobs/terraform_gated_destroy.yml:
# AzDOEnvironmentName (duplicated from schemas/terraform_destroy_config.yml for clear
# standalone errors), RunMode, and the verification timeout fields.

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
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
  },
  @{
    Description = "with RunMode set to DestroyOnly"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "DestroyOnly"
      }
    }
  },
  @{
    Description = "with RunMode set to PlanVerifyDestroy"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
      }
    }
  },
  @{
    Description = "with valid VerificationTimeoutInMinutes and VerificationTimeoutBehaviour"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutInMinutes = 30
        VerificationTimeoutBehaviour = "resume"
      }
    }
  },
  @{
    Description = "with VerificationTimeoutInMinutes at lower boundary (1)"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutInMinutes = 1
      }
    }
  },
  @{
    Description = "with VerificationTimeoutInMinutes at upper boundary (43200)"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutInMinutes = 43200
      }
    }
  }
)

$invalidTestCases = @(
  @{
    Description = "missing EnvironmentName parameter"
    Parameters = @{
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
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
    Description = "missing AzDOEnvironmentName in TerraformDestroyConfig"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        RunMode = "PlanOnly"
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
    Description = "missing RunMode in config"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: RunMode is not properly defined and is a required field. Must be a valid option (PlanVerifyDestroy, PlanOnly, DestroyOnly).'"
  },
  @{
    Description = "empty RunMode value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = ""
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: RunMode is not properly defined and is a required field. Must be a valid option (PlanVerifyDestroy, PlanOnly, DestroyOnly).'"
  },
  @{
    Description = "invalid RunMode value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "InvalidMode"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: RunMode must be a valid option (PlanVerifyDestroy, PlanOnly, DestroyOnly).'"
  },
  @{
    Description = "invalid VerificationTimeoutBehaviour value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutBehaviour = "invalid"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: VerificationTimeoutBehaviour must be either 'reject' or 'resume'.'"
  },
  @{
    Description = "VerificationTimeoutInMinutes below minimum (0)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
        VerificationTimeoutInMinutes = 0
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: VerificationTimeoutInMinutes must be a number between 1 and 43200 (30 days).'"
  },
  @{
    Description = "VerificationTimeoutInMinutes above maximum (43201)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDestroyConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanVerifyDestroy"
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
  -YamlPath "schemas/terraform_gated_destroy_config.yml" `
  -TransformYamlFunction { param($yaml) return $yaml + @"
  - job:
    steps:
    - script: echo `"Hello World`"
"@ } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
