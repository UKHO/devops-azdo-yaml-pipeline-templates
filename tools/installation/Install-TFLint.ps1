# Script to install tflint if not already installed

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
Write-Host "Installing TFLint" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define tflint download URL and package information
$tflintWindowsUrl = "https://github.com/terraform-linters/tflint/releases/download/v0.50.3/tflint_windows_amd64.zip"

# Install tflint using utility function
Invoke-ToolInstallation `
  -ToolName "tflint" `
  -ChocoPackageName "tflint" `
  -WindowsDownloadUrl $tflintWindowsUrl `
  -ExecutableName "tflint.exe"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TFLint installation complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

