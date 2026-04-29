# ============================================================================
# TEST FRAMEWORK - ORCHESTRATOR & ENTRY POINTS
# ============================================================================
# Main entry point for the testing framework.
# Initializes environment, loads modules, and exposes public test functions.

$RepositoryRoot = git rev-parse --show-toplevel 2> $null
$frameworkRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Config = & (Join-Path $frameworkRoot "Config.ps1")

$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($Config.TestExecution.ShowVerboseOutput) { 'Continue' } else { 'SilentlyContinue' }

# ============================================================================
# INITIALIZATION
# ============================================================================

# Auto-load all test framework modules
Get-ChildItem -Path $frameworkRoot -Filter "Core.*.ps1" | ForEach-Object { . $_.FullName }

# Initialize shared test state
# NOTE: This is maintained here for backward compatibility and shared configuration
$script:TestState = @{
  TestsRun = 0
  TestsPassed = 0
  TestsFailed = 0
  FailedTests = @()
  TargetBranch = $Config.TargetBranch
  SkipValidation = $Config.Validation.SkipValidation
  AzDO = $Config.AzDO
  SaveCompiledYaml = $Config.SaveCompiledYaml
  AccessToken = $null
}

# Perform preflight validation checks
Invoke-PreFlightValidation

# Obtain Azure DevOps authentication token
$script:TestState.AccessToken = Get-AccessToken
$script:TestState.PreflightCompleted = $true

# ============================================================================
# PUBLIC ENTRY POINTS
# ============================================================================

<#
.SYNOPSIS
  Run parameterised tests against a YAML template.

.DESCRIPTION
  Executes multiple test cases (with different parameters) against a single
  YAML template file. Each test case can validate successful compilation
  or failure scenarios.

.PARAMETER YamlPath
  Path to the YAML template file (relative to repository root).

.PARAMETER TransformYamlFunction
  Optional script block to transform YAML content before testing.

.PARAMETER ValidTestCases
  Array of test cases that should compile successfully.

.PARAMETER InvalidTestCases
  Array of test cases that should fail compilation.

.EXAMPLE
  Run-Tests -YamlPath "tasks/terraform.yml" -ValidTestCases @(...) -InvalidTestCases @(...)
#>
function Run-Tests
{
  param(
    [Parameter(Mandatory)]
    [string]
    $YamlPath,

    [Parameter()]
    [scriptblock]
    $TransformYamlFunction,

    [Parameter(Mandatory)]
    [array]
    $ValidTestCases,

    [Parameter(Mandatory)]
    [array]
    $InvalidTestCases
  )

  # Delegate to parameterised test runner
  Invoke-ParameterisedTests -YamlPath $YamlPath `
    -TransformYamlFunction $TransformYamlFunction `
    -ValidTestCases $ValidTestCases `
    -InvalidTestCases $InvalidTestCases
}

<#
.SYNOPSIS
  Run compilation tests for all YAML files in a directory.

.DESCRIPTION
  Discovers all *_test.yml files in a directory (including subdirectories)
  and tests each one for successful compilation. Useful for batch testing
  multiple templates without complex parameterised test cases.

.PARAMETER DirectoryPath
  Path to the directory containing test files (relative to repository root).

.EXAMPLE
  Run-DirectoryCompileTests -DirectoryPath "tests/jobs/terraform_build"
#>
function Run-DirectoryCompileTests
{
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DirectoryPath
  )

  # Delegate to directory test runner
  Invoke-DirectoryCompileTests -DirectoryPath $DirectoryPath
}

Write-Verbose "Test Framework loaded"
