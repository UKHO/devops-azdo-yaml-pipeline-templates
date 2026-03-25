#!/usr/bin/env pwsh
<#
.SYNOPSIS
  Run all tests using the simple PowerShell test framework.

.DESCRIPTION
  Loads Config.ps1, validates the environment (including automatic Azure DevOps
  sign-in if needed), and discovers/executes all test files matching the pattern
  defined in Config.ps1.

  This is a pure PowerShell Core replacement for Pester that eliminates:
  - Scope issues
  - Silent sign-in failures
  - Configuration embedded in code
  - Pester DSL learning curve

.PARAMETER Verbose
  Enable verbose output for debugging.

.EXAMPLE
  # Run all tests
  pwsh ./run-tests.ps1

  # Run with verbose output
  pwsh ./run-tests.ps1 -Verbose

.NOTES
  Configuration is loaded from tests/framework/Config.ps1
  Update that file with your Azure DevOps organization details.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

# Paths
$repoRoot = $PSScriptRoot
$frameworkRoot = Join-Path $repoRoot "tests" "framework"

# Load configuration
Write-Verbose "Loading configuration..."
$configPath = Join-Path $frameworkRoot "Config.ps1"

if (-not (Test-Path $configPath))
{
  Write-Error "Configuration file not found: $configPath"
  exit 1
}

$config = & $configPath

# Load framework
Write-Verbose "Loading test framework..."
$corePath = Join-Path $frameworkRoot "Core.ps1"

if (-not (Test-Path $corePath))
{
  Write-Error "Test framework core not found: $corePath"
  exit 1
}

try
{
  . $corePath
}
catch
{
  Write-Error "Failed to load test framework: $_"
  exit 1
}

# Run tests
try
{
  Write-Host "🧪 TEST EXECUTION" -ForegroundColor Cyan
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

  # Discover test files
  $pattern = $config.TestDiscovery.Pattern
  $searchPath = Join-Path $repoRoot $pattern
  $parentDir = Split-Path $searchPath
  $filterPattern = Split-Path -Leaf $searchPath

  $testFiles = @()
  if (Test-Path (Split-Path $parentDir))
  {
    $testFiles = @(Get-ChildItem -Path (Split-Path $parentDir) -Filter $filterPattern -Recurse -ErrorAction SilentlyContinue)
  }

  if ($testFiles.Count -eq 0)
  {
    Write-Host "⚠️  No test files found matching pattern: $pattern" -ForegroundColor Yellow
    exit 0
  }

  Write-Host "Found $( $testFiles.Count ) test file(s)`n"
  $testFiles | ForEach-Object { Write-Host "  - $($_.FullName)" -ForegroundColor Gray }
  Write-Host ""

  # Execute each test file
  foreach ($testFile in $testFiles)
  {
    & $testFile.FullName
  }

  Write-Host "✅  All tests completed" -ForegroundColor Green
}
catch
{
  Write-Error "Test execution failed: $_"
  exit 1
}

