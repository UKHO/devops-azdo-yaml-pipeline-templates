# ============================================================================
# Run All Compile Tests in Repository
# ============================================================================
# This script discovers all *.CompileTests.ps1 files and runs them sequentially

param(
  [switch]$Verbose = $false
)

# Get the repository root
$repoRoot = git rev-parse --show-toplevel 2> $null
if (-not $repoRoot) {
  Write-Error "Could not determine repository root. Make sure you're in a Git repository."
  exit 1
}

Write-Host "Repository Root: $repoRoot" -ForegroundColor Cyan

# Discover all *.CompileTests.ps1 files
$testFiles = @(Get-ChildItem -Path $repoRoot -Filter "*.CompileTests.ps1" -Recurse)

if ($testFiles.Count -eq 0) {
  Write-Warning "No *.CompileTests.ps1 files found in repository."
  exit 0
}

Write-Host "Found $($testFiles.Count) compile test file(s):" -ForegroundColor Cyan
$testFiles | ForEach-Object { Write-Host "  - $($_.FullName)" -ForegroundColor Gray }
Write-Host ""

# Run each test file sequentially
$passedCount = 0
$failedCount = 0
$failedTests = @()

foreach ($testFile in $testFiles) {
  $testName = Join-Path $testFile.Directory.Name $testFile.Name
  Write-Host "Running: $testName" -ForegroundColor Yellow
  Write-Host ($('-' * 80)) -ForegroundColor Gray

  try {
    # Reset so a non-zero exit code left over from an earlier native command
    # (git, az, ...) cannot mark this file as failed.
    $global:LASTEXITCODE = 0

    # Run the test script. Test failures are reported by throwing (see
    # TestExecution.ThrowExceptionOnTestFailure), which is handled by the catch below.
    & $testFile.FullName

    # A test script may also signal failure explicitly with 'exit <non-zero>'
    if ($LASTEXITCODE -ne 0) {
      Write-Host "✗ FAILED (Exit Code: $LASTEXITCODE)" -ForegroundColor Red
      $failedCount++
      $failedTests += $testName
    } else {
      Write-Host "✓ PASSED" -ForegroundColor Green
      $passedCount++
    }
  }
  catch {
    Write-Host "✗ ERROR: $_" -ForegroundColor Red
    $failedCount++
    $failedTests += $testName
  }

  Write-Host ""
}

# Summary
Write-Host ("=" * 80) -ForegroundColor Gray
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "  Passed: $passedCount" -ForegroundColor Green
Write-Host "  Failed: $failedCount" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($failedCount -gt 0) {
  Write-Host "Failed Tests:" -ForegroundColor Red
  $failedTests | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
  Write-Host ""
  exit 1
} else {
  Write-Host "All tests passed! ✓" -ForegroundColor Green
  exit 0
}
