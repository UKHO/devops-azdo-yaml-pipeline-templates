param(
  [Parameter()]
  [string]$RepositoryRoot = (git rev-parse --show-toplevel 2> $null) ?? (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

# ============================================================================
# CONFIGURATION
# ============================================================================

# Determine the framework root directory (where Core.ps1 is located)
# Use $MyInvocation.MyCommand.Path to get the actual path of this script
$frameworkRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# Load environment-specific configuration
$configPath = Join-Path $frameworkRoot "Config.ps1"
$environmentConfig = & $configPath

$script:TestFrameworkConfig = @{
  RepositoryRoot = $RepositoryRoot
  TestFrameworkRoot = $frameworkRoot

  # Pipeline compilation settings (loaded from Config.ps1)
  CompileBaseParams = $environmentConfig.CompileBaseParams

  # Validation settings (loaded from Config.ps1)
  ValidationSettings = $environmentConfig.Validation

  # Paths to framework components
  ScriptsPath = Join-Path $frameworkRoot "scripts"
  HelpersPath = Join-Path $frameworkRoot "helpers"
  AssertionsPath = Join-Path $frameworkRoot "assertions"
  TestCaseTemplatePath = Join-Path $frameworkRoot "templates"
}

# ============================================================================
# IMPORT CORE FRAMEWORK COMPONENTS AT MODULE LEVEL
# ============================================================================
# These need to be imported at the script scope level so they're available
# to all test blocks, not just inside Initialize-TestEnvironment
# Using dot-sourcing with $PSScriptRoot ensures they're loaded in the correct context

if (Test-Path (Join-Path $script:TestFrameworkConfig.HelpersPath "Test-CompileYaml.ps1"))
{
  . (Join-Path $script:TestFrameworkConfig.HelpersPath "Test-CompileYaml.ps1")
}

if (Test-Path (Join-Path $script:TestFrameworkConfig.AssertionsPath "Pipeline.Assertions.ps1"))
{
  . (Join-Path $script:TestFrameworkConfig.AssertionsPath "Pipeline.Assertions.ps1")
}

# ============================================================================
# PATH UTILITIES
# ============================================================================

<#
.SYNOPSIS
Get the repository root directory.
#>
function Get-RepositoryRoot
{
  return $script:TestFrameworkConfig.RepositoryRoot
}

<#
.SYNOPSIS
Resolve a path relative to the repository root.

.PARAMETER RelativePath
The path relative to repository root.

.EXAMPLE
Get-RepositoryPath "pipelines/infrastructure_pipeline.yml"
#>
function Get-RepositoryPath
{
  param(
    [Parameter(Mandatory)]
    [string]$RelativePath
  )

  return Join-Path $script:TestFrameworkConfig.RepositoryRoot $RelativePath
}

<#
.SYNOPSIS
Get the test framework root directory.
#>
function Get-TestFrameworkRoot
{
  return $script:TestFrameworkConfig.TestFrameworkRoot
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

<#
.SYNOPSIS
Verify that Azure DevOps CLI is installed and available.

.DESCRIPTION
Checks if the Azure DevOps CLI extension is installed by attempting to
execute 'az devops --version'. Returns $true if available, $false otherwise.

.EXAMPLE
Test-AzDevOpsCli

.RETURNS
$true if Azure DevOps CLI is available, $false otherwise.
#>
function Test-AzDevOpsCli
{
  try
  {
    $null = az devops --version 2>$null
    return $true
  }
  catch
  {
    return $false
  }
}

<#
.SYNOPSIS
Verify that the user is authenticated with Azure (has az account context loaded).

.DESCRIPTION
Checks if the user has an active Azure authentication context by attempting
to execute 'az account show'. Returns $true if authenticated, $false otherwise.

.EXAMPLE
Test-AzAuthentication

.RETURNS
$true if user is authenticated, $false otherwise.
#>
function Test-AzAuthentication
{
  $output = az account show --output json 2>&1
  return $LASTEXITCODE -eq 0
}

<#
.SYNOPSIS
Verify that configuration values are not null or empty.

.DESCRIPTION
Validates that all required configuration parameters (Organization, Project, PipelineId)
have valid non-empty values. Returns $true if all are valid, $false otherwise.

.EXAMPLE
Test-ConfigurationValues

.RETURNS
$true if all configuration values are valid, $false otherwise.
#>
function Test-ConfigurationValues
{
  $config = $script:TestFrameworkConfig.CompileBaseParams

  return (
    -not [string]::IsNullOrWhiteSpace($config.Organization) -and
    -not [string]::IsNullOrWhiteSpace($config.Project) -and
    $null -ne $config.PipelineId -and
    $config.PipelineId -gt 0
  )
}

<#
.SYNOPSIS
Perform comprehensive validation of the test framework environment.

.DESCRIPTION
Validates that the test framework is properly configured and all prerequisites are met:
- Configuration values are valid (Organization, Project, PipelineId)
- Azure DevOps CLI is installed
- User is authenticated with Azure (has valid az account context)

Validation checks are controlled by settings in Config.ps1. If any check fails and
FailOnValidationError is $true, an exception is thrown with remediation guidance.
If FailOnValidationError is $false, only warnings are output.

.EXAMPLE
Test-TestFrameworkEnvironment

.RETURNS
$true if all validations pass, $false otherwise (unless FailOnValidationError is $true).
#>
function Test-TestFrameworkEnvironment
{
  $validationSettings = $script:TestFrameworkConfig.ValidationSettings
  $failOnError = $validationSettings.FailOnValidationError
  $allValidationsPassed = $true
  $validationErrors = @()

  # Validate configuration values
  if ($validationSettings.CheckConfigValues)
  {
    Write-Verbose "Validating configuration values..."
    if (-not (Test-ConfigurationValues))
    {
      $validationErrors += "Configuration values are invalid or empty (Organization: '$($script:TestFrameworkConfig.CompileBaseParams.Organization)', Project: '$($script:TestFrameworkConfig.CompileBaseParams.Project)', PipelineId: $($script:TestFrameworkConfig.CompileBaseParams.PipelineId))"
      $allValidationsPassed = $false
    }
    else
    {
      Write-Verbose "Configuration values are valid"
    }
  }

  # Validate Azure DevOps CLI
  if ($validationSettings.CheckAzDevOpsCli)
  {
    Write-Verbose "Checking Azure DevOps CLI installation..."
    if (-not (Test-AzDevOpsCli))
    {
      $validationErrors += "Azure DevOps CLI is not installed or not available in PATH"
      $allValidationsPassed = $false
    }
    else
    {
      Write-Verbose "Azure DevOps CLI is available"
    }
  }

  # Validate Azure authentication
  if ($validationSettings.CheckAzAuthentication)
  {
    Write-Verbose "Checking Azure authentication status..."
    if (-not (Test-AzAuthentication))
    {
      $validationErrors += "User is not authenticated with Azure. Run 'az login' to authenticate"
      $allValidationsPassed = $false
    }
    else
    {
      Write-Verbose "User is authenticated with Azure"
    }
  }

  # Handle validation results
  if (-not $allValidationsPassed)
  {
    $errorMessage = @"
Test framework environment validation failed:

$($validationErrors -join "`n`n")

Remediation steps:
1. Install Azure DevOps CLI: az extension add --name azure-devops
2. Authenticate with Azure: az login
3. Update Config.ps1 with correct Organization, Project, and PipelineId values
"@

    if ($failOnError)
    {
      throw $errorMessage
    }
    else
    {
      Write-Warning $errorMessage
      return $false
    }
  }

  Write-Verbose "All test framework environment validations passed"
  return $true
}

# ============================================================================
# TEST EXECUTION HELPERS
# ============================================================================

<#
.SYNOPSIS
Initialize test environment for a test file.

.DESCRIPTION
This function must be called at the beginning of any test file (in BeforeAll).
It sets up the script scope variables and imports all framework components.

Performs validation of the test framework environment:
- Checks configuration values
- Verifies Azure DevOps CLI is installed
- Verifies user has valid Azure authentication context (az account)

If validation fails and FailOnValidationError is $true, an exception is thrown.
If FailOnValidationError is $false, only warnings are shown.

Test cases should be defined inline in the test file before this is called.

.PARAMETER TestFilePath
The path to the test file being run (use $PSScriptRoot).

.EXAMPLE
Initialize-TestEnvironment -TestFilePath $PSScriptRoot
#>
function Initialize-TestEnvironment
{
  # Validate environment before initializing
  Test-TestFrameworkEnvironment | Out-Null

  # Set up base parameters
  $script:CompileBaseParams = $script:TestFrameworkConfig.CompileBaseParams
  $script:RepositoryRoot = $script:TestFrameworkConfig.RepositoryRoot
  $script:InvokePipelineCompilePath = Join-Path $script:TestFrameworkConfig.ScriptsPath "Invoke-PipelineCompile.ps1"
  $script:TestFrameworkRoot = $script:TestFrameworkConfig.TestFrameworkRoot
}

<#
.SYNOPSIS
Initialize test environment specifically for task template tests.

.DESCRIPTION
This function must be called at the beginning of any task template test file (in BeforeAll).
It extends Initialize-TestEnvironment to also:
- Load the corresponding task template YAML file
- Make valid and invalid test cases available to the test

The task template filename is automatically derived from the test file name.
For example, MyTask.Tests.ps1 will load tasks/MyTask.yml.

By default, the function looks for the task template in the standard location (tasks/ directory).
For tests in non-standard locations (e.g., examples/), use the TaskTemplatePath parameter to
specify the relative path to the task template.

Test cases should be defined inline in the test file as $validTestCases and $invalidTestCases
before this function is called.

.PARAMETER TestFilePath
The path to the test file being run (use $PSScriptRoot).

.PARAMETER TaskTemplatePath
Optional. Path to the task template file relative to repository root.
If not specified, defaults to "tasks/{TaskName}.yml".
Use this for tests in non-standard locations (e.g., "tasks/examples/my_task.yml").

.EXAMPLE
# Standard task location (tasks/my_task.yml)
Initialize-TaskTestEnvironment -TestFilePath $PSScriptRoot

.EXAMPLE
# Custom task location (tasks/examples/my_task.yml)
Initialize-TaskTestEnvironment -TestFilePath $PSScriptRoot -TaskTemplatePath "tasks/examples/my_task.yml"
#>
function Initialize-TaskTestEnvironment
{
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$TestFilePath,

    [Parameter()]
    [string]$TaskTemplatePath
  )
  Initialize-TestEnvironment

  # Load the task template YAML file
  # Derives the task template filename from the test file name (e.g., MyTask.Tests.ps1 -> MyTask.yml)
  $taskFileName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath) -replace '\.Tests$', ''

  # Use provided path or default to tasks directory
  if ([string]::IsNullOrWhiteSpace($TaskTemplatePath))
  {
    $taskTemplatePath = Get-RepositoryPath "tasks/$taskFileName.yml"
  }
  else
  {
    $taskTemplatePath = Get-RepositoryPath $TaskTemplatePath
  }

  $script:TaskTemplate = Get-Content -Path $taskTemplatePath -Raw

  # Only assign test cases if they exist as local variables
  # (they may already be defined at script scope in the test file)
  if ($null -ne (Get-Variable -Name validTestCases -ErrorAction SilentlyContinue))
  {
    $script:ValidTestCases = $validTestCases
  }
  if ($null -ne (Get-Variable -Name invalidTestCases -ErrorAction SilentlyContinue))
  {
    $script:InvalidTestCases = $invalidTestCases
  }
}

<#
.SYNOPSIS
Load test cases from a test case file.

.PARAMETER TestCaseFile
Path to the .testcases.ps1 file.

.EXAMPLE
$validCases = Load-TestCases -TestCaseFile "C:\path\to\valid.testcases.ps1"
#>
function Load-TestCases
{
  param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$TestCaseFile
  )

  return & $TestCaseFile
}

<#
.SYNOPSIS
Load test cases from multiple files by pattern.

.PARAMETER Pattern
Glob pattern to match test case files (e.g., "*.testcases.ps1").

.PARAMETER TestDirectory
Directory to search for test case files. Defaults to current directory.

.EXAMPLE
$cases = Load-TestCasesByPattern -Pattern "*.testcases.ps1" -TestDirectory $PSScriptRoot
#>
function Load-TestCasesByPattern
{
  param(
    [Parameter(Mandatory)]
    [string]$Pattern,

    [Parameter()]
    [string]$TestDirectory = $PSScriptRoot
  )

  $cases = @()
  $testCaseFiles = Get-ChildItem -Path $TestDirectory -Filter $Pattern -File

  foreach ($file in $testCaseFiles)
  {
    $fileCases = & $file.FullName
    $cases += $fileCases
  }

  return $cases
}

# ============================================================================
# DISCOVERY HELPERS
# ============================================================================

<#
.SYNOPSIS
Discover all test files in the repository.

.DESCRIPTION
Searches the repository for test files following the naming convention
'*.Tests.ps1' or '*-Tests.ps1'.

.PARAMETER Pattern
Glob pattern for test file discovery. Default: '**/*.Tests.ps1'

.EXAMPLE
$allTests = Find-RepositoryTestFiles
$pipelineTests = Find-RepositoryTestFiles -Pattern "pipelines/**/Tests.ps1"
#>
function Find-RepositoryTestFiles
{
  param(
    [Parameter()]
    [string]$Pattern = "**/*.Tests.ps1"
  )

  $testRoot = $script:TestFrameworkConfig.RepositoryRoot

  # Convert pattern to file system pattern
  $searchPath = Join-Path $testRoot $Pattern

  return Get-ChildItem -Path (Split-Path $searchPath) -Filter (Split-Path $searchPath -Leaf) -Recurse -ErrorAction SilentlyContinue
}

# ============================================================================
# EXPORT CONFIGURATION
# ============================================================================

Write-Verbose "Test framework initialized. Repository root: $( $script:TestFrameworkConfig.RepositoryRoot )"
