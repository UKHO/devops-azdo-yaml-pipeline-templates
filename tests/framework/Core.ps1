$RepositoryRoot = git rev-parse --show-toplevel 2> $null
$frameworkRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Config = & (Join-Path $frameworkRoot "Config.ps1")

$ErrorActionPreference = 'Stop'

$script:TestState = @{
  RepositoryRoot = $RepositoryRoot
  FrameworkRoot = $frameworkRoot
  Config = $Config
  TestsRun = 0
  TestsPassed = 0
  TestsFailed = 0
  FailedTests = @()
  CompileBaseParams = $Config.AzureDevOps
}

. (Join-Path $frameworkRoot "Core.Utilities.ps1")
. (Join-Path $frameworkRoot "Core.StartUpValidation.ps1")
. (Join-Path $frameworkRoot "Core.Test-Yaml.ps1")

function Invoke-Test
{
  param([string]$TestName, [scriptblock]$TestScript, [string]$TestFile = "")
  $script:TestState.TestsRun++
  try
  {
    $result = & $TestScript
    if ($result -eq $false)
    {
      Write-Host "  ✗ $TestName" -ForegroundColor Red
      $script:TestState.TestsFailed++
      $script:TestState.FailedTests += @{ Name = $TestName; File = $TestFile; Error = "Test returned false" }
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
  if ($ValidTestCases.Count -gt 0)
  {
    Write-Host "`n✓ Valid Test Cases:" -ForegroundColor Yellow
    foreach ($testCase in $ValidTestCases)
    {
      Invoke-Test -TestName "Should compile: $( $testCase.Description )" -TestScript {
        $result = Test-CompileYaml -YamlContent $yaml -Arguments $testCase.Parameters
        return ($result.success -eq $true -or $result.id -ne $null)
      } -TestFile $PSCommandPath
    }
  }
  if ($InvalidTestCases.Count -gt 0)
  {
    Write-Host "`n✗ Invalid Test Cases (should fail):" -ForegroundColor Yellow
    foreach ($testCase in $InvalidTestCases)
    {
      Invoke-Test -TestName "Should reject: $( $testCase.Description )" -TestScript {
        $result = Test-CompileYaml -YamlContent $yaml -Arguments $testCase.Parameters
        return ($result.success -eq $false -or $result.error -ne $null)
      } -TestFile $PSCommandPath
    }
  }
  Write-Host "`n"
}
Write-Verbose "Test Framework loaded"
