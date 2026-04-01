function Run-Test
{
  param([string]$Yaml, [array]$TestCases, [scriptblock]$PassCriteriaFunction, [scriptblock]$ErrorMessageFunction, [string]$TestCasesTitle, [string]$TestFilePath, [string]$TemplateName)
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

        # Save compiled YAML if enabled and compilation was successful
        if ($script:TestState.SaveCompiledYaml -and $null -ne $result.finalYaml)
        {
          Save-CompiledYamlToFile -TestFilePath $TestFilePath `
            -TemplateName $TemplateName `
            -TestCaseDescription $testCase.Description `
            -CompiledYaml $result.finalYaml
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
      Write-Host "  ✗ $TestName" -ForegroundColor Red
      Write-Host "    Error: $( $result.FailureMessage )" -ForegroundColor Red
      Write-Host ""
      $script:TestState.TestsFailed++
      $script:TestState.FailedTests += @{ Name = $TestName; File = $TestFile; Error = $result.FailureMessage }
    }
    else
    {
      Write-Host "  ✓ $TestName" -ForegroundColor Green
      Write-Host ""
      $script:TestState.TestsPassed++
    }
  }
  catch
  {
    Write-Host "  ✗ $TestName" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
    Write-Host ""
    $script:TestState.TestsFailed++
    $script:TestState.FailedTests += @{ Name = $TestName; File = $TestFile; Error = $_.Exception.Message }
  }
}
