# ============================================================================
# TEST FRAMEWORK - DIRECTORY TEST RUNNER
# ============================================================================
$script:DirectoryTestState = @{
  FilesFound    = 0
  FilesRun      = 0
  Passed        = 0
  Failed        = 0
  Results       = @()
  ErrorMessages = @()
  DirectoryPath = ""
}
function Invoke-DirectoryCompileTests
{
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DirectoryPath
  )
  try
  {
    script:Initialize-DirectoryTestState
    $script:DirectoryTestState.DirectoryPath = $DirectoryPath
    script:Test-DirectoryTestInput -DirectoryPath $DirectoryPath
    Write-Host "`nTesting Directory: $DirectoryPath" -ForegroundColor Cyan
    Write-Host ("=" * ($DirectoryPath.Length + 20)) -ForegroundColor Cyan
    $testFiles = script:Find-TestYamlFilesInDirectory -DirectoryPath $DirectoryPath
    $script:DirectoryTestState.FilesFound = $testFiles.Count
    if ($testFiles.Count -eq 0)
    {
      Write-Host "  Info: No *_test.yml files found in directory" -ForegroundColor Yellow
    }
    else
    {
      foreach ($testFile in $testFiles)
      {
        script:Run-DirectoryTest -YamlFilePath $testFile
      }
    }
    Write-Host "`n"
    script:Format-DirectoryTestOutput
    script:Throw-OnDirectoryTestFailure
  }
  catch
  {
    Write-Host "Error during directory test execution: $_" -ForegroundColor Red
    throw
  }
}
function script:Initialize-DirectoryTestState
{
  $script:DirectoryTestState = @{
    FilesFound    = 0
    FilesRun      = 0
    Passed        = 0
    Failed        = 0
    Results       = @()
    ErrorMessages = @()
    DirectoryPath = ""
  }
}
function script:Find-TestYamlFilesInDirectory
{
  param(
    [Parameter(Mandatory)]
    [string]
    $DirectoryPath
  )
  $fullPath = Join-Path $RepositoryRoot $DirectoryPath
  try
  {
    Write-Verbose "Discovering *_test.yml files in: $fullPath (recursive)"
    $testFiles = @(Get-ChildItem -Path $fullPath -Filter "*_test.yml" -Recurse -File | Select-Object -ExpandProperty FullName)
    Write-Verbose "Discovered $($testFiles.Count) test file(s)"
    return $testFiles
  }
  catch
  {
    Write-Host "Error discovering test files: $_" -ForegroundColor Red
    throw
  }
}
function script:Test-DirectoryTestInput
{
  param(
    [Parameter(Mandatory)]
    [string]
    $DirectoryPath
  )
  $fullPath = Join-Path $RepositoryRoot $DirectoryPath
  if (-not (Test-Path -Path $fullPath -PathType Container))
  {
    throw "Directory not found: $fullPath"
  }
  Write-Verbose "Directory validated: $fullPath"
}
function script:Run-DirectoryTest
{
  param(
    [Parameter(Mandatory)]
    [string]
    $YamlFilePath
  )
  $script:DirectoryTestState.FilesRun++
  try
  {
    $displayName = script:Get-TestFileDisplayName -FilePath $YamlFilePath
    $relativeDirectory = [System.IO.Path]::GetDirectoryName($YamlFilePath.Substring($RepositoryRoot.Length + 1))
    Write-Host "  Testing: $displayName" -ForegroundColor Cyan
    $yamlContent = Get-Content -Path $YamlFilePath -Raw
    $result = Test-CompileYaml -YamlContent $yamlContent -Parameters @{}
    $testPassed = script:Evaluate-DirectoryCompilationResult -CompileResult $result
    if ($testPassed)
    {
      Write-Host "    [PASS] Default compilation" -ForegroundColor Green
      $script:DirectoryTestState.Passed++
      $script:DirectoryTestState.Results += @{
        Name    = $displayName
        Group   = $relativeDirectory
        Success = $true
        Error   = $null
        Type    = "DirectoryCompile"
      }
    }
    else
    {
      $errorMsg = if ($null -eq $result.finalYaml)
      {
        if ($result.error -and $result.error.apiMessage)
        {
          "Compilation failed: $($result.error.apiMessage)"
        }
        else
        {
          "Compilation failed: finalYaml is null"
        }
      }
      else
      {
        "Compilation result validation failed"
      }
      Write-Host "    [FAIL] Default compilation" -ForegroundColor Red
      Write-Host "      Error: $errorMsg" -ForegroundColor Red
      $script:DirectoryTestState.Failed++
      $script:DirectoryTestState.ErrorMessages += @{ Name = $displayName; Path = $YamlFilePath; Error = $errorMsg }
      $script:DirectoryTestState.Results += @{
        Name    = $displayName
        Group   = $relativeDirectory
        Success = $false
        Error   = $errorMsg
        Type    = "DirectoryCompile"
      }
    }
    Write-Host ""
  }
  catch
  {
    Write-Host "    [FAIL] Default compilation" -ForegroundColor Red
    Write-Host "      Error: $_" -ForegroundColor Red
    Write-Host ""
    $displayName = script:Get-TestFileDisplayName -FilePath $YamlFilePath
    $relativeDirectory = [System.IO.Path]::GetDirectoryName($YamlFilePath.Substring($RepositoryRoot.Length + 1))
    $script:DirectoryTestState.Failed++
    $script:DirectoryTestState.ErrorMessages += @{ Name = $displayName; Path = $YamlFilePath; Error = $_.Exception.Message }
    $script:DirectoryTestState.Results += @{
      Name    = $displayName
      Group   = $relativeDirectory
      Success = $false
      Error   = $_.Exception.Message
      Type    = "DirectoryCompile"
    }
  }
}
function script:Evaluate-DirectoryCompilationResult
{
  param(
    [Parameter(Mandatory)]
    [object]
    $CompileResult
  )
  $hasValidId = $null -ne $CompileResult.id -and $CompileResult.id -eq -1
  $hasFinalYaml = $null -ne $CompileResult.finalYaml
  return ($hasValidId -and $hasFinalYaml)
}
function script:Get-TestFileDisplayName
{
  param(
    [Parameter(Mandatory)]
    [string]
    $FilePath
  )
  $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
  return $fileName
}
function script:Format-DirectoryTestOutput
{
  $state = $script:DirectoryTestState
  Write-Host "============================================================" -ForegroundColor Cyan
  Write-Host "Directory Test Summary" -ForegroundColor Cyan
  Write-Host "============================================================" -ForegroundColor Cyan
  Write-Host "  Files Discovered: $($state.FilesFound)"
  Write-Host "  Files Tested:     $($state.FilesRun)"
  Write-Host "  Passed:           $($state.Passed)" -ForegroundColor Green
  Write-Host "  Failed:           $($state.Failed)" -ForegroundColor $(if ($state.Failed -gt 0) { "Red" } else { "Green" })
  if ($state.ErrorMessages.Count -gt 0)
  {
    Write-Host "`nFailed Tests:" -ForegroundColor Yellow
    foreach ($failedTest in $state.ErrorMessages)
    {
      Write-Host "  - $($failedTest.Name)" -ForegroundColor Red
    }
  }
  Write-Host ""
}
function script:Throw-OnDirectoryTestFailure
{
  if ($Config.TestExecution.ThrowExceptionOnTestFailure -and $script:DirectoryTestState.Failed -gt 0)
  {
    throw "Directory test run completed with $($script:DirectoryTestState.Failed) failed test(s)."
  }
}
Write-Verbose "Directory Test Runner loaded"
