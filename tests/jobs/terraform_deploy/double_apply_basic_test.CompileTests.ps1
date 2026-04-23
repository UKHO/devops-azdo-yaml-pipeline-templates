# ============================================================================
# TEST: Double Apply Basic
# ============================================================================
# Tests two Apply deployments running in parallel with different artifacts

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
  -YamlPath "tests/jobs/terraform_deploy/double_apply_basic_test.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

