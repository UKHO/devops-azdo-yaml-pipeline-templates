# ============================================================================
# TEST: Apply Without Output Variables
# ============================================================================
# Tests Apply mode without output variable export

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
    Description = "with default parameters"
    Parameters = @{ }
    ExpectedYaml = @(
      "displayName: Terraform Apply"
      "TerraformDeployApply"
    )
  }
)

# Invalid test cases
$invalidTestCases = @(
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tests/jobs/terraform_deploy/apply_without_output_variables_test.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

