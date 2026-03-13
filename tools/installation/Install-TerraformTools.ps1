# Master script to install all Terraform tools

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
Write-Host "Installing Terraform Tools" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ...existing code...
# Install TFLint
& "$(Join-Path $PSScriptRoot 'Install-TFLint.ps1')"

Write-Host ""

# Install TFSort
& "$(Join-Path $PSScriptRoot 'Install-TFSort.ps1')"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All Terraform tools installation complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

