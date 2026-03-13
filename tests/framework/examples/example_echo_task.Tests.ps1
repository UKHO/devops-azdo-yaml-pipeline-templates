# Define valid test cases with different parameter combinations
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
  },
  @{
    # Note: Azure DevOps does not enforce 'values:' constraints at compile time.
    # An out-of-range value is only rejected at queue/run time, not by the API.
    Description = "with invalid verbosityLevel value (values: not enforced at compile time)"
    Parameters = @{
      message = "Test message"
      verbosityLevel = "invalid"
    }
  }
)

# Define invalid test cases
$invalidTestCases = @(
  @{
    Description = "with empty message parameter"
    Parameters = @{
      message = ""
      verbosityLevel = "info"
    }
  }
)

BeforeAll {
  $repoRoot = git rev-parse --show-toplevel 2>$null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
  Initialize-TaskTestEnvironment `
    -TestFilePath $PSScriptRoot `
    -TaskTemplatePath "tests/framework/examples/example_echo_task.yml"
}

Describe "Example Echo Task Template" {
  Context "Valid YAML Compilation" {
    It "should compile with valid parameters: <Description>" -TestCases $validTestCases {
      param($Description, $Parameters)

      $result = Test-CompileYaml -YamlContent $script:TaskTemplate -Arguments $Parameters
      $result | Assert-PipelineCompilationSuccess
    }
  }

  Context "Invalid YAML Compilation" {
    It "should reject invalid parameters: <Description>" -TestCases $invalidTestCases {
      param($Description, $Parameters)

      $result = Test-CompileYaml -YamlContent $script:TaskTemplate -Arguments $Parameters
      $result | Assert-PipelineCompilationFailure
    }
  }
}






