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
  }
)

# Invalid test cases
$invalidTestCases = @()

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tests/pipelines/infrastructure_pipeline/linux_test.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
