# ============================================================================
# TEST: Terraform Build with Additional Files to Package
# ============================================================================
# This test verifies that the terraform_build job can package additional
# files beyond the terraform files themselves.

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
  -YamlPath "tests/jobs/terraform_build/additional_files_test.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases

