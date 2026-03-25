# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue)) {
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

$validTestCases = @(
  @{
    Description = "with required parameters filled out"
    Parameters  = @{
      Command        = "init"
    }
  }
)

$invalidTestCases = @(
  @{
    Description = "with no parameters"
    Parameters  = @{
    }
    ErrorMessage = "A value for the 'Command' parameter must be provided."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tasks/terraform.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
