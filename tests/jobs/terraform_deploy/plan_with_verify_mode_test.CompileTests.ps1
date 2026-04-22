# ============================================================================
# TEST: Plan with Verification Disabled
# ============================================================================
# Tests Plan mode with verification disabled (auto-approve)

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
      "VerifyDisabled"
      "TerraformChangesCheck"
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
  -YamlPath "tests/jobs/terraform_deploy/plan_with_verify_mode_test.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

