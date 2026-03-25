# ============================================================================
# TEST: Example Echo Task Template
# ============================================================================
# This test demonstrates how to write tests using the simple PowerShell framework.

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue)) {
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
    ErrorMessage = "The 'message' parameter is not a valid String."
  },
  @{
    Description = "with invalid verbosityLevel value"
    Parameters  = @{
      message        = "Test message"
      verbosityLevel = "invalid"
    }
    ErrorMessage = "The 'verbosityLevel' parameter value 'invalid' is not a valid value."
  }
)

# ============================================================================
# RUN TESTS
# ============================================================================

Run-Tests `
  -YamlPath "tests/framework/example_echo_task.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
