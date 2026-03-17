param(
  [Parameter()]
  [ValidateScript({ Test-Path $_ })]
  [string]
  $File,

  [Parameter()]
  [ValidateSet('Normal', 'Detailed', 'Diagnostic')]
  [string]
  $Output = 'Detailed',

  [Parameter()]
  [switch]
  $PassThru,

  [Parameter()]
  [string]
  $ExportResults
)

$ErrorActionPreference = 'Stop'

$repoRoot = git rev-parse --show-toplevel 2>$null

Write-Host "Repository root: $repoRoot" -ForegroundColor Cyan
Write-Host ""

. (Join-Path $repoRoot "tests" "framework" "Core.ps1") -RepositoryRoot $repoRoot

Write-Host "Validating test environment..." -ForegroundColor Cyan
Test-TestFrameworkEnvironment | Out-Null
Write-Host "Environment validation passed" -ForegroundColor Green
Write-Host ""

$testFiles = @(Get-Item -Path $File -ErrorAction Stop)
Write-Host "Running single test file: $File" -ForegroundColor Green

$config = New-PesterConfiguration
$config.Run.Path = $testFiles.FullName
$config.Output.Verbosity = $Output
$config.TestResult.Enabled = $true

if ($ExportResults)
{
  $config.TestResult.OutputPath = $ExportResults
  $config.TestResult.OutputFormat = if ($ExportResults -like "*.xml")
  {
    'NUnitXml'
  }
  else
  {
    'Json'
  }
  Write-Host "Exporting results to: $ExportResults" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Running tests..." -ForegroundColor Cyan
Write-Host ""

$results = Invoke-Pester -Configuration $config
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Test Summary:" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Passed:  $( $results.Tests.Passed.Count )" -ForegroundColor Green
Write-Host "  Failed:  $( $results.Tests.Failed.Count )" -ForegroundColor $( if ($results.Tests.Failed.Count -gt 0)
{
  'Red'
}
else
{
  'Green'
} )
Write-Host "  Skipped: $( $results.Tests.Skipped.Count )" -ForegroundColor Yellow
Write-Host "  Total:   $( $results.Tests.Count )"
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($PassThru)
{
  return $results
}

exit $results.FailedCount

