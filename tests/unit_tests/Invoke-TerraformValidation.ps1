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

# Import helper module
$helperModulePath = Join-Path $PSScriptRoot "Invoke-TerraformHelper.psm1"
if (-not (Test-Path $helperModulePath))
{
  Write-Host "ERROR: Helper module not found at $helperModulePath" -ForegroundColor Red
  exit 1
}
Import-Module $helperModulePath -Force

# Define path to terraform_azdo directory
$scriptPath = Split-Path -Parent $PSScriptRoot
$repositoryRoot = (git rev-parse --show-toplevel)
$terraformAzdoPath = Join-Path $scriptPath "unit_tests" "terraform_azdo"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting validation checks on terraform_azdo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if terraform_azdo directory exists
if (-not (Test-Path $terraformAzdoPath))
{
  Write-Host "terraform_azdo directory not found: $terraformAzdoPath" -ForegroundColor Red
  exit 1
}

# Change to terraform_azdo directory
Set-Location $terraformAzdoPath

Write-Host "Working directory: $( Get-Location )" -ForegroundColor Gray

# Terraform init (without backend)
$command = "terraform init -backend=false"
Invoke-CommandWithLogging -Command $command -ExitOnFailure

# Terraform fmt
$command = "terraform fmt -recursive"
Invoke-CommandWithLogging -Command $command

# Tfsort
$command = "tfsort ."
Invoke-CommandWithLogging -Command $command

# Terraform validate
$command = "terraform validate"
Invoke-CommandWithLogging -Command $command -ExitOnFailure

# Run TFLint
$command = "tflint --config=`"$repositoryRoot/.tflint.hcl`""
Invoke-CommandWithLogging -Command $command

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Validation checks complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

