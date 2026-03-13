# Define valid test cases with different parameter combinations
# Parameters should match the task template's parameters
$validTestCases = @(
  # Add valid test cases here
  # @{
  #   Description = "Example: valid parameter combination"
  #   Parameters = @{
  #     param1 = "value1"
  #     param2 = "value2"
  #   }
  # }
)

# Define invalid test cases with parameters that should fail
$invalidTestCases = @(
  # Add invalid test cases here
  # @{
  #   Description = "Example: missing required parameter"
  #   Parameters = @{
  #     param1 = "value1"
  #     # param2 is missing and required
  #   }
  #   ExpectedMessage = "parameter 'param2' is required"
  # }
)

BeforeAll {
  $repoRoot = git rev-parse --show-toplevel 2>$null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
  Initialize-TaskTestEnvironment -TestFilePath $PSScriptRoot
}

Describe "Template Tests" {
  Context "Valid YAML Compilation" {
    It "should compile with valid parameters: <Description>" -TestCases $script:ValidTestCases -Skip:($script:ValidTestCases.Count -eq 0) {
      param($Description, $Parameters)

      $result = Test-CompileYaml -YamlContent $script:TaskTemplate -Arguments $Parameters
      $result | Assert-PipelineCompilationSuccess
    }
  }

  Context "Invalid YAML Compilation" {
    It "should reject invalid parameters: <Description>" -TestCases $script:InvalidTestCases -Skip:($script:InvalidTestCases.Count -eq 0) {
      param($Description, $Parameters)

      $result = Test-CompileYaml -YamlContent $script:TaskTemplate -Arguments $Parameters
      $result | Assert-PipelineCompilationFailure
    }
  }
}
