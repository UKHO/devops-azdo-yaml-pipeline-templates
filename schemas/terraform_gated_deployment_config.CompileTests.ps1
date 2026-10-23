# ============================================================================
# TEST: TERRAFORM GATED DEPLOYMENT CONFIG SCHEMA
# ============================================================================
# Validates only the properties consumed directly by jobs/terraform_gated_deployment.yml:
# AzDOEnvironmentName (duplicated from schemas/terraform_deploy_config.yml for clear
# standalone errors), RunMode, VerificationMode-required-when-RunMode-is-PlanVerifyApply,
# the verification timeout fields, and ApplyEvenIfNoChanges.

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
  },
  @{
    Description = "with ApplyEvenIfNoChanges set to true and RunMode PlanVerifyApply"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        ApplyEvenIfNoChanges = $true
      }
    }
  },
  @{
    Description = "with ApplyEvenIfNoChanges set to false and RunMode PlanVerifyApply"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        ApplyEvenIfNoChanges = $false
      }
    }
  },
  @{
    Description = "with ApplyEvenIfNoChanges set to false and RunMode ApplyOnly"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "ApplyOnly"
        ApplyEvenIfNoChanges = $false
      }
    }
  },
  @{
    Description = "with ApplyEvenIfNoChanges set to false and RunMode PlanOnly"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanOnly"
        ApplyEvenIfNoChanges = $false
      }
    }
  },
  # YAML object literals (ApplyEvenIfNoChanges: true) reach templates as strings, not booleans,
  # so the string forms must be accepted - this is how real consumer pipelines pass the value.
  @{
    Description = "with ApplyEvenIfNoChanges set to string 'true' (YAML literal form) and RunMode PlanVerifyApply"
    Parameters = @{
      EnvironmentName = "prod"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "prod-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        ApplyEvenIfNoChanges = "true"
      }
    }
  },
  @{
    Description = "with ApplyEvenIfNoChanges set to string 'false' (YAML literal form) and RunMode ApplyOnly"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "ApplyOnly"
        ApplyEvenIfNoChanges = "false"
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
  },
  @{
    Description = "ApplyEvenIfNoChanges set to true with RunMode PlanOnly"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanOnly"
        ApplyEvenIfNoChanges = $true
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: ApplyEvenIfNoChanges can only be set to true when RunMode is PlanVerifyApply.'"
  },
  @{
    Description = "ApplyEvenIfNoChanges set to true with RunMode ApplyOnly"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "ApplyOnly"
        ApplyEvenIfNoChanges = $true
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: ApplyEvenIfNoChanges can only be set to true when RunMode is PlanVerifyApply.'"
  },
  @{
    Description = "ApplyEvenIfNoChanges set to a non-boolean value"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        ApplyEvenIfNoChanges = "yes"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: ApplyEvenIfNoChanges must be a boolean (true or false).'"
  },
  # Regression: notIn() coerces right-hand operands to the left-hand type, so numeric 1/0
  # used to pass validation. In PlanVerifyApply, 1 then rendered as eq('1', 'true') and silently
  # left the override disabled. The schema must enforce the JSON boolean type.
  @{
    Description = "ApplyEvenIfNoChanges set to numeric 1 with RunMode PlanVerifyApply"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        ApplyEvenIfNoChanges = 1
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: ApplyEvenIfNoChanges must be a boolean (true or false).'"
  },
  @{
    Description = "ApplyEvenIfNoChanges set to numeric 0 with RunMode PlanVerifyApply"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        ApplyEvenIfNoChanges = 0
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: ApplyEvenIfNoChanges must be a boolean (true or false).'"
  },
  @{
    Description = "ApplyEvenIfNoChanges set to numeric 1 with RunMode ApplyOnly (type error, not RunMode error)"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "ApplyOnly"
        ApplyEvenIfNoChanges = 1
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: ApplyEvenIfNoChanges must be a boolean (true or false).'"
  },
  @{
    Description = "ApplyEvenIfNoChanges set to string '1' (YAML literal form) with RunMode PlanVerifyApply"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanVerifyApply"
        VerificationMode = "VerifyOnAny"
        ApplyEvenIfNoChanges = "1"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: ApplyEvenIfNoChanges must be a boolean (true or false).'"
  },
  @{
    Description = "ApplyEvenIfNoChanges set to string 'true' (YAML literal form) with RunMode PlanOnly"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "dev-environment"
        RunMode = "PlanOnly"
        ApplyEvenIfNoChanges = "true"
      }
    }
    ErrorMessage = "Unexpected value ''dev' environment error: ApplyEvenIfNoChanges can only be set to true when RunMode is PlanVerifyApply.'"
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
