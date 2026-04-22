# ============================================================================
# TEST: Apply with Multiple Output Variables
# ============================================================================
# Tests Apply mode exporting multiple Terraform output variables

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
      "TerraformExportOutputsVariables"
      "terraform-output.json"
      "random_number,random_string"
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
  -YamlPath "tests/jobs/terraform_deploy/apply_with_multiple_output_variables_test.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

