#Requires -Version 5.1
<#
.SYNOPSIS
    Runs validation checks on Terraform configuration files.

.DESCRIPTION
    This script performs the following validation operations on Terraform code:
    - terraform fmt: Formats code to canonical style
    - tfsort: Sorts Terraform blocks for consistency
    - terraform validate: Validates syntax and configuration
    - tflint: Lints code against best practices

    No authentication required for validation.

.EXAMPLE
    .\Invoke-TerraformValidation.ps1

#>

$helperModulePath = Join-Path $PSScriptRoot "Invoke-TerraformHelper.psm1"
if (-not (Test-Path $helperModulePath))
{
  Write-Host "ERROR: Helper module not found at $helperModulePath" -ForegroundColor Red
  exit 1
}
Import-Module $helperModulePath -Force

$repoRoot = git rev-parse --show-toplevel
$terraformAzdoPath = Join-Path $repoRoot "tests" "terraform_azdo"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting validation checks on terraform_azdo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $terraformAzdoPath))
{
  Write-Host "terraform_azdo directory not found: $terraformAzdoPath" -ForegroundColor Red
  exit 1
}

Set-Location $terraformAzdoPath
Write-Host "Working directory: $( Get-Location )" -ForegroundColor Gray

Invoke-CommandWithLogging -Command "terraform init -backend=false" -ExitOnFailure
Invoke-CommandWithLogging -Command "terraform fmt -recursive"
Invoke-CommandWithLogging -Command "tfsort ."
Invoke-CommandWithLogging -Command "terraform validate" -ExitOnFailure
Invoke-CommandWithLogging -Command "tflint --config=`"$repoRoot/.tflint.hcl`""

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Validation checks complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

