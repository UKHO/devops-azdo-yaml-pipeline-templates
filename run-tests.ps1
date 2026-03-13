param(
  [Parameter()]
  [string]
  $Path = "**/*.Tests.ps1",

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

$repoRoot = Split-Path -Parent $MyInvocation.MyCommandPath
if ((Split-Path -Leaf $repoRoot) -eq 'tests')
{
  $repoRoot = Split-Path -Parent $repoRoot
}

Write-Host "Repository root: $repoRoot" -ForegroundColor Cyan
Write-Host ""

$frameworkPath = Join-Path $repoRoot "tests" "framework" "Core.ps1"
if (-not (Test-Path $frameworkPath))
{
  Write-Error "Test framework not found at: $frameworkPath"
  exit 1
}

. $frameworkPath -RepositoryRoot $repoRoot

if ($File)
{
  $testFiles = @(Get-Item -Path $File -ErrorAction Stop)
  Write-Host "Running single test file: $File" -ForegroundColor Green
}
else
{
  $searchPath = Join-Path $repoRoot $Path
  $testFiles = @(Get-ChildItem -Path (Split-Path $searchPath) -Include (Split-Path $searchPath -Leaf) -Recurse -ErrorAction SilentlyContinue)

  if ($testFiles.Count -eq 0)
  {
    Write-Host "No test files found matching pattern: $Path" -ForegroundColor Yellow
    exit 0
  }

  Write-Host "Discovered $($testFiles.Count) test file(s):" -ForegroundColor Green
  $testFiles | ForEach-Object { Write-Host "  - $($_.FullName)" }
  Write-Host ""
}

$config = New-PesterConfiguration
$config.Run.Path = $testFiles.FullName
$config.Output.Verbosity = $Output
$config.TestResult.Enabled = $true

if ($ExportResults)
{
  $config.TestResult.OutputPath = $ExportResults
  $config.TestResult.OutputFormat = if ($ExportResults -like "*.xml") { 'NUnitXml' } else { 'Json' }
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
Write-Host "  Passed:  $($results.Tests.Passed.Count)" -ForegroundColor Green
Write-Host "  Failed:  $($results.Tests.Failed.Count)" -ForegroundColor $(if ($results.Tests.Failed.Count -gt 0) { 'Red' } else { 'Green' })
Write-Host "  Skipped: $($results.Tests.Skipped.Count)" -ForegroundColor Yellow
Write-Host "  Total:   $($results.Tests.Count)"
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan

if ($PassThru)
{
  return $results
}

exit $results.FailedCount

