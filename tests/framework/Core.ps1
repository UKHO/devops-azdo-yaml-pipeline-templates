$RepositoryRoot = git rev-parse --show-toplevel 2> $null
$frameworkRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Config = & (Join-Path $frameworkRoot "Config.ps1")

$ErrorActionPreference = 'Stop'
$VerbosePreference = $Config.TestExecution.ShowVerboseOutput ? 'Continue' : 'SilentlyContinue'

Get-ChildItem -Path $frameworkRoot -Filter "Core.*.ps1" | ForEach-Object { . $_.FullName }

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

Invoke-PreFlightValidation
$script:TestState.AccessToken = Get-AccessToken
$script:TestState.PreflightCompleted = $true

function Run-Tests
{
  param([string]$YamlPath, [scriptblock]$TransformYamlFunction, [array]$ValidTestCases, [array]$InvalidTestCases)

  $yamlFullPath = Join-Path $RepositoryRoot $YamlPath
  $yaml = Get-Content -Path $yamlFullPath -Raw
  if ($null -ne $TransformYamlFunction) {
    $yaml = & $TransformYamlFunction $yaml
  }
  $TestName = [System.IO.Path]::GetFileNameWithoutExtension($YamlPath)
  $TestDirectoryPath = [System.IO.Path]::GetDirectoryName($yamlFullPath)

  Write-Host "`nTesting: $TestName" -ForegroundColor Cyan
  Write-Host ("━" * ($TestName.Length + 10)) -ForegroundColor Cyan

  # Valid test case criteria
  $validPassCriteria = {
    $hasValidId = $null -ne $result.id -and $result.id -eq -1
    $hasFinalYaml = $result.finalYaml -ne $null
    $expectedYamlFound = $testCase.ExpectedYaml -eq $null -or @($testCase.ExpectedYaml | Where-Object { $result.finalYaml -notlike "*$_*" }).Count -eq 0

    return ($hasValidId -and $hasFinalYaml -and $expectedYamlFound)
  }

  $validErrorMessage = {
    $hasFinalYaml = $result.finalYaml -ne $null
    $expectedYamlFound = $testCase.ExpectedYaml -eq $null -or @($testCase.ExpectedYaml | Where-Object { $result.finalYaml -notlike "*$_*" }).Count -eq 0

    if (-not $hasFinalYaml)
    {
      if ($result.error -ne $null -and $result.error.apiMessage -ne $null)
      {
        return "Expected finalYaml to be populated, but it was null or empty. API Error: $( $result.error.apiMessage )"
      }
      return "Expected finalYaml to be populated, but it was null or empty. Indication that the compilation did not complete successfully."
    }
    else
    {
      return "Final YAML:`n$( $result.finalYaml )`ndid not contain the following expected YAML: '$( $testCase.ExpectedYaml -join "', '" )'."
    }
  }

  # Invalid test case criteria
  $invalidPassCriteria = {
    $testFailed = $result.success -eq $false
    $correctStatusCode = $result.error.statusCode -eq 400
    $errorMessageMatches = $testCase.ErrorMessage -eq "" -or $result.error.apiMessage -like "*$( $testCase.ErrorMessage )*"

    return ($testFailed -and $correctStatusCode -and $errorMessageMatches)
  }

  $invalidErrorMessage = {
    if ($null -ne $result.id -and $result.id -eq -1)
    {
      return "Expected test to fail, but it compiled successfully. Final YAML:`n$( $result.finalYaml )"
    }
    elseif ($null -ne $result.error -and $result.error.statusCode -ne 400)
    {
      return "Expected error status code 400, but got $( $result.error.statusCode ). Error: $( $result.error.apiMessage )"
    }
    else
    {
      return "Expected error message '$( $testCase.ErrorMessage )' not found. Actual error: $( $result.error.apiMessage )"
    }
  }

  Run-Test -Yaml $yaml -TestCases $validTestCases -PassCriteriaFunction $validPassCriteria `
    -TestCasesTitle "`n✓ Valid Test Cases:" -ErrorMessageFunction $validErrorMessage `
    -TestFilePath $TestDirectoryPath -TemplateName $TestName

  Run-Test -Yaml $yaml -TestCases $invalidTestCases -PassCriteriaFunction $invalidPassCriteria `
    -TestCasesTitle "`n✗ Invalid Test Cases (should fail):" -ErrorMessageFunction $invalidErrorMessage `
    -TestFilePath $TestDirectoryPath -TemplateName $TestName

  Write-Host "`n"

  Get-TestSummary

  Throw-ExceptionOnTestFailure
}

function Get-TestSummary
{
  [CmdletBinding()]
  param()

  $state = $script:TestState
  Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host "📊 TEST SUMMARY" -ForegroundColor Cyan
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host "  Tests Run:    $( $state.TestsRun )"
  Write-Host "  Passed:       $( $state.TestsPassed )" -ForegroundColor Green
  Write-Host "  Failed:       $( $state.TestsFailed )" -ForegroundColor $( if ($state.TestsFailed -gt 0)
  {
    'Red'
  }
  else
  {
    'Green'
  } )

  if ($state.FailedTests.Count -gt 0)
  {
    Write-Host "`n⚠️  Failed Tests:" -ForegroundColor Yellow
    foreach ($failedTest in $state.FailedTests)
    {
      Write-Host "  - $( $failedTest.Name )" -ForegroundColor Red
    }
  }
  Write-Host ""
}

function Throw-ExceptionOnTestFailure
{
  if ($Config.TestExecution.ThrowExceptionOnTestFailure -and $script:TestState.TestsFailed -gt 0)
  {
    throw "Test run completed with $( $script:TestState.TestsFailed ) failed test(s)."
  }
}

Write-Verbose "Test Framework loaded"
