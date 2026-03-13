# Test-PipelineYaml.ps1
# Validates a YAML pipeline by compiling it and checking the result against expected outcomes.
#
# This function is designed for testing different YAML variations to verify they either:
# - Compile successfully (Run object returned)
# - Fail with specific error codes and messages (Error object with validation details)
#
# USAGE EXAMPLES:
# ===============
#
# Example 1: Test expecting successful compilation
#   $yaml = @"
#   trigger:
#     - main
#   pool:
#     vmImage: 'ubuntu-latest'
#   steps:
#     - script: echo Hello, world!
#   "@
#
#   $result = Test-PipelineYaml -YamlContent $yaml `
#     -Organization "myorg" `
#     -Project "myproject" `
#     -PipelineId 1 `
#     -ExpectSuccess $true
#
#   if ($result.passed) {
#     Write-Host "Test passed! Pipeline compiled successfully."
#   } else {
#     Write-Host "Test failed: $($result.message)"
#   }
#
# Example 2: Test expecting compilation failure with specific error
#   $yaml = @"
#   trigger:
#     - main
#   "invalid key": error
#   pool:
#     vmImage: 'ubuntu-latest'
#   "@
#
#   $result = Test-PipelineYaml -YamlContent $yaml `
#     -Organization "myorg" `
#     -Project "myproject" `
#     -PipelineId 1 `
#     -ExpectSuccess $false `
#     -ExpectStatusCode 400 `
#     -ExpectMessageContains "invalid key"
#
#   if ($result.passed) {
#     Write-Host "Test passed! Got expected compilation error."
#   } else {
#     Write-Host "Test failed: $($result.message)"
#   }
#
# Example 3: Test expecting a specific error message in customProperties
#   $yaml = @"
#   trigger:
#     - main
#   pool: invalid_syntax
#   steps: also_invalid
#   "@
#
#   $result = Test-PipelineYaml -YamlContent $yaml `
#     -Organization "myorg" `
#     -Project "myproject" `
#     -PipelineId 1 `
#     -ExpectSuccess $false `
#     -ExpectErrorDetailContains "Expected mapping"
#
#   if ($result.passed) {
#     Write-Host "Test passed! Got expected YAML parsing error."
#   } else {
#     Write-Host "Test failed: $($result.message)"
#   }

[CmdletBinding()]
param (
  [Parameter(Mandatory,
    HelpMessage = "The YAML pipeline content to test.")]
  [ValidateNotNullOrEmpty()]
  [string] $YamlContent,

  [Parameter(Mandatory,
    HelpMessage = "Azure DevOps organization name.")]
  [ValidateNotNullOrEmpty()]
  [string] $Organization,

  [Parameter(Mandatory,
    HelpMessage = "Azure DevOps project name.")]
  [ValidateNotNullOrEmpty()]
  [string] $Project,

  [Parameter(Mandatory,
    HelpMessage = "Pipeline ID to compile against.")]
  [ValidateRange(1, [int]::MaxValue)]
  [int] $PipelineId,

  [Parameter()]
  [hashtable] $Arguments = @{},

  [Parameter(Mandatory,
    HelpMessage = "Whether the YAML compilation is expected to succeed.")]
  [bool] $ExpectSuccess,

  [Parameter()]
  [ValidateRange(200, 599)]
  [int] $ExpectStatusCode,

  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string] $ExpectMessageContains,

  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string] $ExpectErrorDetailContains,

  [Parameter()]
  [string] $TestName = "YAML Compilation Test",

  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [string] $InvokeScriptPath = "$PSScriptRoot\Invoke-PipelineCompile.ps1"
)

try {
  Write-Verbose "Starting test: $TestName"
  Write-Verbose "Organization: $Organization | Project: $Project | Pipeline ID: $PipelineId"
  Write-Verbose "Expecting success: $ExpectSuccess"

  # Call the compilation script
  Write-Verbose "Invoking pipeline compilation..."
  $compilationResult = & $InvokeScriptPath `
    -YamlContent $YamlContent `
    -Organization $Organization `
    -Project $Project `
    -PipelineId $PipelineId `
    -Arguments $Arguments `
    -Verbose:$VerbosePreference

  # Validate that we got a result
  if ($null -eq $compilationResult) {
    Write-Error "Compilation script returned null"
    return @{
      passed = $false
      message = "Compilation script returned null result"
      compilationResult = $null
      details = @("The Invoke-PipelineCompile.ps1 script did not return a valid response")
    }
  }

  # Validate the result
  $testResult = @{
    passed = $true
    message = ""
    compilationResult = $compilationResult
    details = @()
  }

  if ($ExpectSuccess) {
    # Expecting successful compilation - should NOT have success property or success should be $true
    if ($null -ne $compilationResult.success -and $compilationResult.success -eq $false) {
      $testResult.passed = $false
      $testResult.message = "Expected compilation to succeed but got error: $($compilationResult.error.message)"
      $testResult.details += "Status Code: $($compilationResult.error.statusCode)"
      return $testResult
    }

    # Successful compilation should have an 'id' property
    if (-not $compilationResult.id) {
      $testResult.passed = $false
      $testResult.message = "Expected successful compilation with Run ID, but no ID found in response"
      return $testResult
    }

    $testResult.message = "Successfully compiled. Run ID: $($compilationResult.id)"
    Write-Verbose "Test PASSED: $($testResult.message)"
  }
  else {
    # Expecting compilation failure
    if ($null -eq $compilationResult.success -or $compilationResult.success -ne $false) {
      $testResult.passed = $false
      $testResult.message = "Expected compilation to fail, but it succeeded with Run ID: $($compilationResult.id)"
      return $testResult
    }

    # Check status code if specified
    if ($PSBoundParameters.ContainsKey('ExpectStatusCode')) {
      if ($compilationResult.error.statusCode -ne $ExpectStatusCode) {
        $testResult.passed = $false
        $testResult.message = "Expected status code $ExpectStatusCode but got $($compilationResult.error.statusCode)"
        $testResult.details += "Error message: $($compilationResult.error.message)"
        return $testResult
      }
      $testResult.details += "Status code matches expected: $ExpectStatusCode"
    }

    # Check error message contains expected text
    if ($PSBoundParameters.ContainsKey('ExpectMessageContains')) {
      $errorMessageToCheck = $compilationResult.error.apiMessage ?? $compilationResult.error.message
      if ($errorMessageToCheck -notlike "*$ExpectMessageContains*") {
        $testResult.passed = $false
        $testResult.message = "Expected error message to contain '$ExpectMessageContains' but got: $errorMessageToCheck"
        return $testResult
      }
      $testResult.details += "Error message contains expected text: '$ExpectMessageContains'"
    }

    # Check error details/customProperties contains expected text
    if ($PSBoundParameters.ContainsKey('ExpectErrorDetailContains')) {
      $errorDetailsJson = $compilationResult.error.customProperties | ConvertTo-Json -Depth 10
      if ($errorDetailsJson -notlike "*$ExpectErrorDetailContains*") {
        $testResult.passed = $false
        $testResult.message = "Expected error details to contain '$ExpectErrorDetailContains' but got: $errorDetailsJson"
        return $testResult
      }
      $testResult.details += "Error details contain expected text: '$ExpectErrorDetailContains'"
    }

    $testResult.message = "Got expected compilation failure"
    Write-Verbose "Test PASSED: $($testResult.message)"
  }

  return $testResult
}
catch {
  Write-Error "Test execution failed: $($_.Exception.Message)"
  return @{
    passed = $false
    message = "Test execution error: $($_.Exception.Message)"
    compilationResult = $null
    details = @($_.Exception.Message)
  }
}

