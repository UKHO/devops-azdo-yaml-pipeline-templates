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
      InfrastructureConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
      }
    }
  },
  @{
    Description = "with empty BackendConfig"
    Parameters = @{
      EnvironmentName = "dev"
      InfrastructureConfig = @{
        AzDOEnvironmentName = "compile-tests-only"
        RunMode = "PlanOnly"
        BackendConfig = @{}
      }
    }
    ExpectedYAML = "- name: BackendConfigCommandOption*value: ''"
  },
  @{
    Description = "with empty BackendConfig"
    Parameters = @{
      EnvironmentName = "dev"
      InfrastructureConfig = @{
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
    Description = "missing InfrastructureConfig parameter"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
    }
    ErrorMessage = "A value for the 'InfrastructureConfig' parameter must be provided."
  },
  @{
    Description = "missing AzDOEnvironmentName"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
      InfrastructureConfig = "{}"
    }
    ErrorMessage = "''compile-tests-only' environment error: AzDOEnvironmentName is not properly defined and is a required field.'"
  },
  @{
    Description = "missing RunMode"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
      InfrastructureConfig = "{}"
    }
    ErrorMessage = "''compile-tests-only' environment error: Must provide a valid RunMode option (PlanVerifyApply, PlanOnly, ApplyOnly).'"
  },
  @{
    Description = "incorrect RunMode"
    Parameters = @{
      EnvironmentName = "compile-tests-only"
      InfrastructureConfig = @{
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
  -TransformYamlFunction { return $yaml -replace 'AzDOPipelineTemplates', 'self' } `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
