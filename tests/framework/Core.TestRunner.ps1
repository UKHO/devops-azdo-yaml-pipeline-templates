function Run-Test
{
  param([string]$Yaml, [array]$TestCases, [scriptblock]$PassCriteriaFunction, [scriptblock]$ErrorMessageFunction, [string]$TestCasesTitle)
  if ($TestCases.Count -gt 0)
  {
    Write-Host $TestCasesTitle -ForegroundColor Yellow
    foreach ($testCase in $TestCases)
    {
      Invoke-Test -TestName "$( $testCase.Description )" -TestScript {
        $result = Test-CompileYaml -YamlContent $yaml -Parameters $testCase.Parameters
        $passed = & $PassCriteriaFunction
        $failureMessage = ""
        if ($passed -eq $false)
        {
          $failureMessage = & $ErrorMessageFunction
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
      Write-Host "  ✗ $TestName - $( $result.FailureMessage )" -ForegroundColor Red
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
