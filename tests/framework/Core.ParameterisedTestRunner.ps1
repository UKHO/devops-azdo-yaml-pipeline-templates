# ============================================================================
# TEST FRAMEWORK - PARAMETERISED TEST RUNNER
# ============================================================================
$script:ParameterisedTestState = @{
  TestsRun = 0
  Passed = 0
  Failed = 0
  Results = @()
  ErrorMessages = @()
}

function Invoke-ParameterisedTests
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
  try
  {
    script:Initialize-ParameterisedTestState
    script:Assert-ParameterisedTestCases -ValidTestCases $ValidTestCases -InvalidTestCases $InvalidTestCases -YamlPath $YamlPath
    $yamlFullPath = Join-Path $RepositoryRoot $YamlPath
    $yaml = Get-Content -Path $yamlFullPath -Raw
    if ($null -ne $TransformYamlFunction)
    {
      $yaml = & $TransformYamlFunction $yaml
    }
    $testName = [System.IO.Path]::GetFileNameWithoutExtension($YamlPath)
    $testDirectoryPath = [System.IO.Path]::GetDirectoryName($yamlFullPath)

    Write-Host "`nTesting: $testName" -ForegroundColor Cyan
    Write-Host ("=" * ($testName.Length + 10)) -ForegroundColor Cyan

    $validPassCriteria = script:Get-ValidPassCriteriaFunction
    $validErrorMessage = script:Get-ValidErrorMessageFunction

    $invalidPassCriteria = script:Get-InvalidPassCriteriaFunction
    $invalidErrorMessage = script:Get-InvalidErrorMessageFunction

    # Compile every test case (valid and invalid) concurrently in a single batch,
    # then evaluate and report the results in their declared order.
    $validTestCases = @($ValidTestCases)
    $invalidTestCases = @($InvalidTestCases)
    $requests = @(@($validTestCases) + @($invalidTestCases) | ForEach-Object {
        @{ YamlContent = $yaml; Parameters = $_.Parameters }
      })
    $allResults = Invoke-CompileYamlBatch -Requests $requests
    $validResults = @()
    $invalidResults = @()
    if ($validTestCases.Count -gt 0)
    {
      $validResults = @($allResults[0..($validTestCases.Count - 1)])
    }
    if ($invalidTestCases.Count -gt 0)
    {
      $invalidResults = @($allResults[$validTestCases.Count..($allResults.Count - 1)])
    }

    script:Run-ParameterisedTest -TestCases $validTestCases -Results $validResults -PassCriteriaFunction $validPassCriteria `
      -TestCasesTitle "`nValid Test Cases:" -ErrorMessageFunction $validErrorMessage `
      -TestFilePath $testDirectoryPath -TemplateName $testName

    script:Run-ParameterisedTest -TestCases $invalidTestCases -Results $invalidResults -PassCriteriaFunction $invalidPassCriteria `
      -TestCasesTitle "`nInvalid Test Cases (should fail):" -ErrorMessageFunction $invalidErrorMessage `
      -TestFilePath $testDirectoryPath -TemplateName $testName
    Write-Host "`n"

    script:Format-ParameterisedTestOutput
    script:Throw-OnParameterisedTestFailure
  }
  catch
  {
    Write-Host "Error during parameterised test execution: $_" -ForegroundColor Red
    throw
  }
}

function script:Initialize-ParameterisedTestState
{
  $script:ParameterisedTestState = @{
    TestsRun = 0
    Passed = 0
    Failed = 0
    Results = @()
    ErrorMessages = @()
  }
}

function script:Assert-ParameterisedTestCases
{
  # Checks the test case definitions before any compile call is made, so a badly defined
  # file fails fast and cheaply. A case that cannot fail for the right reason is a bug in
  # the test file, not a test result.
  param(
    [array]$ValidTestCases,
    [array]$InvalidTestCases,
    [string]$YamlPath
  )
  $problems = @()
  $allCases = @(@($ValidTestCases) + @($InvalidTestCases))

  for ($i = 0; $i -lt $allCases.Count; $i++)
  {
    if ([string]::IsNullOrWhiteSpace($allCases[$i].Description))
    {
      $problems += "Test case #$( $i + 1 ) has no Description."
    }
  }

  $duplicates = @($allCases |
      Where-Object { -not [string]::IsNullOrWhiteSpace($_.Description) } |
      Group-Object -Property { $_.Description } |
      Where-Object { $_.Count -gt 1 })
  foreach ($duplicate in $duplicates)
  {
    $problems += "Description '$( $duplicate.Name )' is used by $( $duplicate.Count ) test cases. Descriptions must be unique."
  }

  foreach ($testCase in @($InvalidTestCases))
  {
    if ([string]::IsNullOrWhiteSpace($testCase.ErrorMessage))
    {
      $problems += "Invalid test case '$( $testCase.Description )' has no ErrorMessage. Without one it would pass on any compile error."
    }
  }

  if ($problems.Count -gt 0)
  {
    throw "Test case definitions for '$YamlPath' are not valid:`n  - $( $problems -join "`n  - " )"
  }
}

function script:Test-ErrorMessageMatch
{
  # ErrorMessage is matched as a literal, case-insensitive substring of the API message.
  # Unlike -like, the characters * ? [ ] have no special meaning, so messages such as
  # "'ConfigSources[].Name' is required" can be asserted exactly.
  param(
    [string]$ApiMessage,
    [string]$ExpectedMessage
  )
  if ($null -eq $ApiMessage -or [string]::IsNullOrEmpty($ExpectedMessage))
  {
    return $false
  }
  return $ApiMessage.IndexOf($ExpectedMessage, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
}

function script:Get-ValidPassCriteriaFunction
{
  return {
    $hasValidId = $null -ne $result.id -and $result.id -eq -1
    $hasFinalYaml = $null -ne $result.finalYaml
    $expectedYamlFound = $null -eq $testCase.ExpectedYaml -or @($testCase.ExpectedYaml | Where-Object { $result.finalYaml -notlike "*$_*" }).Count -eq 0
    $unexpectedYamlAbsent = $null -eq $testCase.UnexpectedYaml -or @($testCase.UnexpectedYaml | Where-Object { $result.finalYaml -like "*$_*" }).Count -eq 0
    return ($hasValidId -and $hasFinalYaml -and $expectedYamlFound -and $unexpectedYamlAbsent)
  }
}

function script:Get-ValidErrorMessageFunction
{
  return {
    $hasFinalYaml = $null -ne $result.finalYaml
    if (-not $hasFinalYaml)
    {
      if ($null -ne $result.error -and $null -ne $result.error.apiMessage)
      {
        return "Expected finalYaml populated; API Error: $( $result.error.apiMessage )"
      }
      return "Expected finalYaml populated but was null or empty."
    }
    else
    {
      $unexpectedFound = @($testCase.UnexpectedYaml | Where-Object { $_ -and $result.finalYaml -like "*$_*" })
      if ($unexpectedFound.Count -gt 0)
      {
        return "Final YAML contained unexpected content:  $( $unexpectedFound -join ", " )`nActual content: $( $result.finalYaml )"
      }
      return "Final YAML did not contain expected content:  $( $testCase.ExpectedYaml -join ", " )`nActual content: $( $result.finalYaml )"
    }
  }
}

function script:Get-InvalidPassCriteriaFunction
{
  return {
    $testFailed = $result.success -eq $false
    $correctStatusCode = $result.error.statusCode -eq 400
    $errorMessageMatches = script:Test-ErrorMessageMatch -ApiMessage $result.error.apiMessage -ExpectedMessage $testCase.ErrorMessage
    return ($testFailed -and $correctStatusCode -and $errorMessageMatches)
  }
}

function script:Get-InvalidErrorMessageFunction
{
  return {
    if ($null -ne $result.id -and $result.id -eq -1)
    {
      return "Expected test to fail but it succeeded: $( $result.finalYaml )"
    }
    elseif ($null -ne $result.error -and $result.error.statusCode -eq 400)
    {
      return "Expected error message containing '$( $testCase.ErrorMessage )' but got: $( $result.error.apiMessage )"
    }
    elseif ($null -ne $result.error -and $result.error.statusCode -ne 400)
    {
      return "Expected error code 400 but got $( $result.error.statusCode ): $( $result.error.apiMessage )"
    }
    else
    {
      return "Expected error not found: $( $testCase.ErrorMessage )"
    }
  }
}

function script:Run-ParameterisedTest
{
  # These parameters are used inside the -TestScript closure below, which PSScriptAnalyzer can't see.
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'Results', Justification = 'Used inside the TestScript closure.')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'PassCriteriaFunction', Justification = 'Used inside the TestScript closure.')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'ErrorMessageFunction', Justification = 'Used inside the TestScript closure.')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TestFilePath', Justification = 'Used inside the TestScript closure.')]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', 'TemplateName', Justification = 'Used inside the TestScript closure.')]
  param(
    [array]$TestCases,
    [array]$Results,
    [scriptblock]$PassCriteriaFunction,
    [scriptblock]$ErrorMessageFunction,
    [string]$TestCasesTitle,
    [string]$TestFilePath,
    [string]$TemplateName
  )
  if ($TestCases.Count -gt 0)
  {
    Write-Host $TestCasesTitle -ForegroundColor Yellow
    for ($testCaseIndex = 0; $testCaseIndex -lt $TestCases.Count; $testCaseIndex++)
    {
      $testCase = $TestCases[$testCaseIndex]
      script:Invoke-ParameterisedTest -TestName "$( $testCase.Description )" -TestScript {
        $result = $Results[$testCaseIndex]
        $passed = & $PassCriteriaFunction
        $failureMessage = ""
        if ($passed -eq $false)
        {
          $failureMessage = & $ErrorMessageFunction
        }
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

function script:Invoke-ParameterisedTest
{
  param(
    [string]$TestName,
    [scriptblock]$TestScript,
    [string]$TestFile = ""
  )
  $script:ParameterisedTestState.TestsRun++
  try
  {
    $result = & $TestScript
    if ($result.Passed -eq $false)
    {
      Write-Host "  [FAIL] $TestName" -ForegroundColor Red
      Write-Host "    Error: $( $result.FailureMessage )" -ForegroundColor Red
      Write-Host ""
      $script:ParameterisedTestState.Failed++
      $script:ParameterisedTestState.ErrorMessages += @{ Name = $TestName; File = $TestFile; Error = $result.FailureMessage }
      $script:ParameterisedTestState.Results += @{
        Name = $TestName
        Group = ""
        Success = $false
        Error = $result.FailureMessage
        Type = "ParameterisedTest"
      }
    }
    else
    {
      Write-Host "  [PASS] $TestName" -ForegroundColor Green
      Write-Host ""
      $script:ParameterisedTestState.Passed++
      $script:ParameterisedTestState.Results += @{
        Name = $TestName
        Group = ""
        Success = $true
        Error = $null
        Type = "ParameterisedTest"
      }
    }
  }
  catch
  {
    Write-Host "  [FAIL] $TestName" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
    Write-Host ""
    $script:ParameterisedTestState.Failed++
    $script:ParameterisedTestState.ErrorMessages += @{ Name = $TestName; File = $TestFile; Error = $_.Exception.Message }
    $script:ParameterisedTestState.Results += @{
      Name = $TestName
      Group = ""
      Success = $false
      Error = $_.Exception.Message
      Type = "ParameterisedTest"
    }
  }
}

function script:Format-ParameterisedTestOutput
{
  $state = $script:ParameterisedTestState
  Write-Host "`n============================================================" -ForegroundColor Cyan
  Write-Host "TEST SUMMARY" -ForegroundColor Cyan
  Write-Host "============================================================" -ForegroundColor Cyan
  Write-Host "  Tests Run:    $( $state.TestsRun )"
  Write-Host "  Passed:       $( $state.Passed )" -ForegroundColor Green
  Write-Host "  Failed:       $( $state.Failed )" -ForegroundColor $( if ($state.Failed -gt 0)
    {
      "Red"
    }
    else
    {
      "Green"
    } )
  if ($state.ErrorMessages.Count -gt 0)
  {
    Write-Host "`nFailed Tests:" -ForegroundColor Yellow
    foreach ($failedTest in $state.ErrorMessages)
    {
      Write-Host "  - $( $failedTest.Name )" -ForegroundColor Red
    }
  }
  Write-Host ""
}

function script:Throw-OnParameterisedTestFailure
{
  if ($Config.TestExecution.ThrowExceptionOnTestFailure -and $script:ParameterisedTestState.Failed -gt 0)
  {
    throw "Test run completed with $( $script:ParameterisedTestState.Failed ) failed test(s)."
  }
}

Write-Verbose "Parameterised Test Runner loaded"
