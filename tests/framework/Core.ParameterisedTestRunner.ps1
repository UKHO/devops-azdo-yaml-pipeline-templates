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

        script:Run-ParameterisedTest -Yaml $yaml -TestCases $validTestCases -PassCriteriaFunction $validPassCriteria `
      -TestCasesTitle "`nValid Test Cases:" -ErrorMessageFunction $validErrorMessage `
      -TestFilePath $testDirectoryPath -TemplateName $testName

        script:Run-ParameterisedTest -Yaml $yaml -TestCases $invalidTestCases -PassCriteriaFunction $invalidPassCriteria `
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

function script:Get-ValidPassCriteriaFunction
{
    return {
        $hasValidId = $null -ne $result.id -and $result.id -eq -1
        $hasFinalYaml = $result.finalYaml -ne $null
        $expectedYamlFound = $testCase.ExpectedYaml -eq $null -or @($testCase.ExpectedYaml | Where-Object { $result.finalYaml -notlike "*$_*" }).Count -eq 0
        return ($hasValidId -and $hasFinalYaml -and $expectedYamlFound)
    }
}

function script:Get-ValidErrorMessageFunction
{
    return {
        $hasFinalYaml = $result.finalYaml -ne $null
        $expectedYamlFound = $testCase.ExpectedYaml -eq $null -or @($testCase.ExpectedYaml | Where-Object { $result.finalYaml -notlike "*$_*" }).Count -eq 0
        if (-not $hasFinalYaml)
        {
            if ($result.error -ne $null -and $result.error.apiMessage -ne $null)
            {
                return "Expected finalYaml populated; API Error: $( $result.error.apiMessage )"
            }
            return "Expected finalYaml populated but was null or empty."
        }
        else
        {
            return "Final YAML did not contain expected content:  $( $testCase.ExpectedYaml -join ", " )`n. Actual content: $( $result.finalYaml )"
        }
    }
}

function script:Get-InvalidPassCriteriaFunction
{
    return {
        $testFailed = $result.success -eq $false
        $correctStatusCode = $result.error.statusCode -eq 400
        $errorMessageMatches = $testCase.ErrorMessage -eq "" -or $result.error.apiMessage -like "*$( $testCase.ErrorMessage )*"
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
    param(
        [string]$Yaml,
        [array]$TestCases,
        [scriptblock]$PassCriteriaFunction,
        [scriptblock]$ErrorMessageFunction,
        [string]$TestCasesTitle,
        [string]$TestFilePath,
        [string]$TemplateName
    )
    if ($TestCases.Count -gt 0)
    {
        Write-Host $TestCasesTitle -ForegroundColor Yellow
        foreach ($testCase in $TestCases)
        {
            script:Invoke-ParameterisedTest -TestName "$( $testCase.Description )" -TestScript {
                $result = Test-CompileYaml -YamlContent $yaml -Parameters $testCase.Parameters
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
