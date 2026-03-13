# Script to install tfsort if not already installed

# Import utility module
$utilsPath = Join-Path $PSScriptRoot "Utils-TerraformTools.ps1"
if (-not (Test-Path $utilsPath))
{
  Write-Host "Utility module not found: $utilsPath" -ForegroundColor Red
  exit 1
}
. $utilsPath

# Check for administrator rights
if (-not (Test-AdminRights))
{
  Request-AdminRights -ScriptPath $MyInvocation.MyCommand.Path
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Installing TFSort" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define tfsort download URL and package information
$tfsortWindowsUrl = "https://github.com/pmorissette/tfsort/releases/download/v0.12.1/tfsort_0.12.1_windows_amd64.tar.gz"

# Install tfsort using utility function
Invoke-ToolInstallation `
  -ToolName "tfsort" `
  -ChocoPackageName "tfsort" `
  -WindowsDownloadUrl $tfsortWindowsUrl `
  -ExecutableName "tfsort"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TFSort installation complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

