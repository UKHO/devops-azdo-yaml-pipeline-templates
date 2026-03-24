$RepositoryRoot = git rev-parse --show-toplevel 2> $null
$frameworkRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Config = & (Join-Path $frameworkRoot "Config.ps1")

$ErrorActionPreference = 'Stop'
$VerbosePreference = $Config.TestExecution.ShowVerboseOutput ? 'Continue' : 'SilentlyContinue'

. (Join-Path $frameworkRoot "Core.Utilities.ps1")
. (Join-Path $frameworkRoot "Core.StartUpValidation.ps1")
. (Join-Path $frameworkRoot "Core.CompileYaml.ps1")
. (Join-Path $frameworkRoot "Core.Tests.ps1")

$script:TestState = @{
  TestsRun = 0
  TestsPassed = 0
  TestsFailed = 0
  FailedTests = @()
  AzDO = $Config.AzDO
  AccessToken = Get-AccessToken
}

function Run-Tests
{
  param([string]$YamlPath, [array]$ValidTestCases, [array]$InvalidTestCases)

  $yaml = Get-Content -Path (Join-Path $RepositoryRoot $YamlPath) -Raw
  $TestName = [System.IO.Path]::GetFileNameWithoutExtension($YamlPath)

  Write-Host "`nTesting: $TestName" -ForegroundColor Cyan
  Write-Host ("━" * ($TestName.Length + 10)) -ForegroundColor Cyan

  Run-Test -Yaml $yaml -TestCases $validTestCases -PassCriteriaFunction {
    return ($null -ne $result.id -and $result.id -eq -1)
  } -TestCasesTitle "`n✓ Valid Test Cases:"

  Run-Test -Yaml $yaml -TestCases $invalidTestCases -PassCriteriaFunction {
    return ($result.success -eq $false -and $result.error.statusCode -eq 400 -and $result.error.apiMessage -like "*$( $testCase.ErrorMessage )*")
  } -TestCasesTitle "`n✗ Invalid Test Cases (should fail):"

  Write-Host "`n"

  Get-TestSummary

  Throw-ExcepionOnTestFailure
}

function Get-TestSummary
{
  [CmdletBinding()]
  param()

  $state = $script:TestState
  Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host "📊 TEST SUMMARY" -ForegroundColor Cyan
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host "  Tests Run:    $($state.TestsRun)"
  Write-Host "  Passed:       $($state.TestsPassed)" -ForegroundColor Green
  Write-Host "  Failed:       $($state.TestsFailed)" -ForegroundColor $(if ($state.TestsFailed -gt 0) { 'Red' } else { 'Green' })

  if ($state.FailedTests.Count -gt 0)
  {
    Write-Host "`n⚠️  Failed Tests:" -ForegroundColor Yellow
    foreach ($failedTest in $state.FailedTests)
    {
      Write-Host "  - $($failedTest.Name)" -ForegroundColor Red
      Write-Host "    Error: $($failedTest.Error)" -ForegroundColor DarkRed
    }
  }
  Write-Host ""
}

function Throw-ExcepionOnTestFailure
{
  if ($Config.TestExecution.ThrowExceptionOnTestFailure -and $script:TestState.TestsFailed -gt 0)
  {
    throw "Test run completed with $($script:TestState.TestsFailed) failed test(s)."
  }
}

Write-Verbose "Test Framework loaded"
