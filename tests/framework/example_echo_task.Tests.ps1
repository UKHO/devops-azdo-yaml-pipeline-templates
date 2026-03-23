# ============================================================================
# TEST: Example Echo Task Template
# ============================================================================
# This test demonstrates how to write tests using the simple PowerShell framework.
# No Pester DSL - just straightforward PowerShell.

# Load framework
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
  $repoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
}
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# ============================================================================
# DEFINE TEST CASES
# ============================================================================

# Valid test cases with different parameter combinations
$validTestCases = @(
  @{
    Description = "with default parameters"
    Parameters  = @{
      message        = "Hello, World!"
      verbosityLevel = "info"
    }
  },
  @{
    Description = "with custom message and debug verbosity"
    Parameters  = @{
      message        = "Starting deployment process"
      verbosityLevel = "debug"
    }
  },
  @{
    # Note: Azure DevOps does not enforce 'values:' constraints at compile time.
    # An out-of-range value is only rejected at queue/run time, not by the API.
    Description = "with invalid verbosityLevel value (values: not enforced at compile time)"
    Parameters  = @{
      message        = "Test message"
      verbosityLevel = "invalid"
    }
  }
)

# Invalid test cases
$invalidTestCases = @(
  @{
    Description = "with empty message parameter"
    Parameters  = @{
      message        = ""
      verbosityLevel = "info"
    }
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tests/framework/example_echo_task.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases






