# ============================================================================
# TEST: Terraform Deploy
# ============================================================================
# This test demonstrates how to write tests using the simple PowerShell framework.

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
    Description = "with required parameters"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
    ExpectedYAML = "displayName: Terraform Plan 'TerraformArtifact'"
  },
  @{
    Description = "with applyonly"
    Parameters = @{
      TerraformDeployMode = "Apply"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "ApplyOnly"
      }
    }
    ExpectedYAML = "displayName: Terraform Apply 'TerraformArtifact'"
  },
  @{
    Description = "with custom artifact name"
    Parameters = @{
      TerraformArtifactName = "CustomArtifact"
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
    ExpectedYAML = "displayName: Terraform Plan 'CustomArtifact'"
  },
  @{
    Description = "with empty BackendConfig"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
        BackendConfig = @{ }
      }
    }
    ExpectedYAML = "- name: BackendConfigCommandOption*value: ''"
  },
  @{
    Description = "with empty BackendConfig"
    Parameters = @{
      EnvironmentName = "dev"
      TerraformDeploymentConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
        BackendConfig = @{
          ConfigKey = "ConfigValue"
        }
      }
    }
    ExpectedYAML = "- name: BackendConfigCommandOption*value: ' -backend-config=`"ConfigKey=ConfigValue`"'"
  }
)

# Invalid test cases
$invalidTestCases = @(
  @{
    Description = "missing EnvironmentName parameter"
    Parameters = @{
    }
    ErrorMessage = "A value for the 'EnvironmentName' parameter must be provided."
  },
  @{
    Description = "missing TerraformDeploymentConfig parameter"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
    }
    ErrorMessage = "A value for the 'TerraformDeploymentConfig' parameter must be provided."
  },
  @{
    Description = "missing AzDOEnvironmentName"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
      TerraformDeploymentConfig = "{}"
    }
    ErrorMessage = "''compile-tests-only' environment error: AzDOEnvironmentName is not properly defined and is a required field.'"
  },
  @{
    Description = "missing RunMode"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
      TerraformDeploymentConfig = "{}"
    }
    ErrorMessage = "''compile-tests-only' environment error: Must provide a valid RunMode option (PlanVerifyApply, PlanOnly, ApplyOnly).'"
  },
  @{
    Description = "incorrect RunMode"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
      TerraformDeploymentConfig = @{
        RunMode = "Plan"
      }
    }
    ErrorMessage = "''compile-tests-only' environment error: Must provide a valid RunMode option (PlanVerifyApply, PlanOnly, ApplyOnly).'"
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
