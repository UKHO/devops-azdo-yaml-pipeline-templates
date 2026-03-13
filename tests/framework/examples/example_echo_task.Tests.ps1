# Define valid test cases with different parameter combinations
# These tests demonstrate what the task should accept
$validTestCases = @(
  @{
    Description = "with default parameters"
    Parameters = @{
      message = "Hello, World!"
      verbosityLevel = "info"
    }
  },
  @{
    Description = "with custom message and debug verbosity"
    Parameters = @{
      message = "Starting deployment process"
      verbosityLevel = "debug"
    }
  }
)

# Define invalid test cases with parameters that should fail
# These tests demonstrate what the task should reject
$invalidTestCases = @(
  @{
    Description = "with empty message parameter"
    Parameters = @{
      message = ""
      verbosityLevel = "info"
    }
  },
  @{
    Description = "with invalid verbosityLevel value"
    Parameters = @{
      message = "Test message"
      verbosityLevel = "invalid"
    }
  }
)

# Source Core.ps1 at script scope (not inside BeforeAll)
# This ensures all imported functions are available to the test blocks
$repoRoot = git rev-parse --show-toplevel 2>$null
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

BeforeAll {
  # Load task template from examples directory instead of default tasks directory
  Initialize-TaskTestEnvironment -TestFilePath $PSScriptRoot -TaskTemplatePath "tests/framework/examples/example_echo_task.yml"
}

Describe "Example Echo Task Template" {
  Context "Valid YAML Compilation" {
    It "should compile with valid parameters: <Description>" -TestCases $script:ValidTestCases {
      param($Description, $Parameters)

      $result = Test-CompileYaml -YamlContent $script:TaskTemplate -Arguments $Parameters
      $result | Assert-PipelineCompilationSuccess
    }
  }

  Context "Invalid YAML Compilation" {
    It "should reject invalid parameters: <Description>" -TestCases $script:InvalidTestCases {
      param($Description, $Parameters)

      $result = Test-CompileYaml -YamlContent $script:TaskTemplate -Arguments $Parameters
      $result | Assert-PipelineCompilationFailure
    }
  }
}

