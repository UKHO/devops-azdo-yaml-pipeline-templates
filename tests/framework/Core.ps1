$RepositoryRoot = git rev-parse --show-toplevel 2> $null
$frameworkRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Config = & (Join-Path $frameworkRoot "Config.ps1")

$ErrorActionPreference = 'Stop'

. (Join-Path $frameworkRoot "Core.Utilities.ps1")
. (Join-Path $frameworkRoot "Core.StartUpValidation.ps1")
. (Join-Path $frameworkRoot "Core.Test-Yaml.ps1")

$script:TestState = @{
  RepositoryRoot = $RepositoryRoot
  FrameworkRoot = $frameworkRoot
  Config = $Config
  TestsRun = 0
  TestsPassed = 0
  TestsFailed = 0
  FailedTests = @()
  CompileBaseParams = $Config.AzureDevOps
  AccessToken = Get-AccessToken
}

function Run-Tests
{
  param([string]$YamlPath, [array]$ValidTestCases, [array]$InvalidTestCases, [string]$TestName = "")
  $yaml = Get-Content -Path (Get-RepositoryPath $YamlPath) -Raw
  if ( [string]::IsNullOrWhiteSpace($TestName))
  {
    $TestName = [System.IO.Path]::GetFileNameWithoutExtension($YamlPath)
  }
  Write-Host "`nTesting: $TestName" -ForegroundColor Cyan
  Write-Host ("━" * ($TestName.Length + 10)) -ForegroundColor Cyan

  Run-Test -Yaml $yaml -TestCases $validTestCases -PassCriteriaFunction {
    return ($null -ne $result.id -and $result.id -eq -1)
  } -TestCasesTitle "`n✓ Valid Test Cases:"

  Run-Test -Yaml $yaml -TestCases $invalidTestCases -PassCriteriaFunction {
    return ($result.success -eq $false -and $result.error.statusCode -eq 400 -and $result.error.apiMessage -like "*$( $testCase.ErrorMessage )*")
  } -TestCasesTitle "`n✗ Invalid Test Cases (should fail):"

  Write-Host "`n"
}

function Run-Test
{
  param([string]$Yaml, [array]$TestCases, [scriptblock]$PassCriteriaFunction, [string]$TestCasesTitle)
  if ($TestCases.Count -gt 0)
  {
    Write-Host $TestCasesTitle -ForegroundColor Yellow
    foreach ($testCase in $TestCases)
    {
      Invoke-Test -TestName "$( $testCase.Description )" -TestScript {
        $result = Test-CompileYaml -YamlContent $yaml -Arguments $testCase.Parameters
        $passed = & $PassCriteriaFunction
        $failureMessage = ""
        if ($passed -eq $false)
        {
          $failureMessage = "Test failed with error: $( $result.error | ConvertTo-Json)"
        }
        return @{
          Passed = $passed
          FailureMessage = $failureMessage
        }
      } -TestFile $PSCommandPath
    }
  }
}

function Invoke-Test
{
  param([string]$TestName, [scriptblock]$TestScript, [string]$TestFile = "")
  $script:TestState.TestsRun++
  try
  {
    $result = & $TestScript
    if ($result.Passed -eq $false)
    {
      Write-Host "  ✗ $TestName - $($result.FailureMessage)" -ForegroundColor Red
      $script:TestState.TestsFailed++
      $script:TestState.FailedTests += @{ Name = $TestName; File = $TestFile; Error = $result.FailureMessage }
    }
    else
    {
      Write-Host "  ✓ $TestName" -ForegroundColor Green
      $script:TestState.TestsPassed++
    }
  }
  catch
  {
    Write-Host "  ✗ $TestName - ERROR: $_" -ForegroundColor Red
    $script:TestState.TestsFailed++
    $script:TestState.FailedTests += @{ Name = $TestName; File = $TestFile; Error = $_.Exception.Message }
  }
}

Write-Verbose "Test Framework loaded"
