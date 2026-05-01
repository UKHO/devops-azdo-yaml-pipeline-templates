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
            CheckoutAlias = "self"
            TerraformDeploymentConfig = @{
                AzDOEnvironmentName = "compile-tests-only"
                RunMode = "PlanOnly"
            }
        }
    },
    @{
        Description = "with applyonly and custom condition"
        Parameters = @{
            EnvironmentName = "dev"
            CheckoutAlias = "self"
            Condition = "always()"
            TerraformDeploymentConfig = @{
                AzDOEnvironmentName = "compile-tests-only"
                RunMode = "ApplyOnly"
            }
        }
        ExpectedYAML = "condition: always()"
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
        }
        ErrorMessage = "A value for the 'TerraformDeploymentConfig' parameter must be provided."
    }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "jobs/terraform_gated_deployment.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
