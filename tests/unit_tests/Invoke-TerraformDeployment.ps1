#Requires -Version 5.1
<#
.SYNOPSIS
    Runs the complete automated Terraform deployment pipeline for CI/CD systems.

.DESCRIPTION
    This script performs the following operations in sequence:
    1. Authenticates to Azure
    2. Initializes Terraform with backend configuration
    3. Validates and formats the Terraform code
    4. Plans the Terraform deployment
    5. Applies the Terraform changes

    This script is designed for automated CI/CD execution without manual intervention.
    It reuses shared validation functions from Invoke-TerraformHelper module to avoid duplication.

.PARAMETER TenantId
    The Azure tenant ID to authenticate against. If not specified, uses default tenant.

.PARAMETER TerraformDirectory
    The directory containing Terraform configuration files. Defaults to current directory.

.PARAMETER VarFile
    Path to the Terraform variables file (.tfvars) to use during plan and apply.
    If not specified, Terraform will use default variable resolution.

.PARAMETER SkipValidation
    If specified, skips the terraform validate and tflint steps. Use cautiously in production.

.PARAMETER BackendConfig
    Hashtable of backend configuration parameters to pass to terraform init.
    Example: @{ key = "value"; container_name = "tfstate"; ... }

.EXAMPLE
    .\Invoke-TerraformDeployment.ps1 `
      -TenantId "00000000-0000-0000-0000-000000000000" `
      -VarFile ".\ukho.tfvars"

.EXAMPLE
    .\Invoke-TerraformDeployment.ps1 `
      -TenantId "00000000-0000-0000-0000-000000000000" `
      -VarFile ".\ukho.tfvars" `
      -SkipValidation

#>

param(
  [Parameter(Mandatory = $false)]
  [AllowNull()]
  [AllowEmptyString()]
  [guid]$TenantId,

  [Parameter(Mandatory = $false)]
  [ValidateScript({
    if (-not (Test-Path -Path $_ -PathType Container))
    {
      throw "TerraformDirectory '$_' does not exist or is not a directory"
    }
    return $true
  })]
  [string]$TerraformDirectory = (Get-Location).Path,

  [Parameter(Mandatory = $false)]
  [ValidateScript({
    if ( [string]::IsNullOrWhiteSpace($_))
    {
      return $true
    }  # Allow null/empty
    if (-not (Test-Path -Path $_ -PathType Leaf))
    {
      throw "VarFile '$_' does not exist or is not a file"
    }
    if (-not ($_ -match '\.tfvars$'))
    {
      throw "VarFile must be a .tfvars file, got: $_"
    }
    return $true
  })]
  [string]$VarFile,

  [Parameter(Mandatory = $false)]
  [switch]$SkipValidation
)

# Set strict error handling
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Import helper module
$helperModulePath = Join-Path $PSScriptRoot "Invoke-TerraformHelper.psm1"
if (-not (Test-Path $helperModulePath))
{
  Write-Host "ERROR: Helper module not found at $helperModulePath" -ForegroundColor Red
  exit 1
}
Import-Module $helperModulePath -Force

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Terraform Automated Deployment Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Terraform Directory: $TerraformDirectory" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
Set-Location $TerraformDirectory
Write-Host "Current Directory: $( Get-Location )" -ForegroundColor Gray
Write-Host ""

# Step 1: Azure Authentication
Write-Host "[1/5] Authenticating to Azure..." -ForegroundColor Green
Connect-ToAzure -TenantId $TenantId
Write-Host ""

# Step 2: Terraform Initialization
Write-Host "[2/5] Initializing Terraform..." -ForegroundColor Green
Initialize-Terraform -BackendConfig $BackendConfig
Write-Host ""

# Step 3: Validation and Formatting
if (-not $SkipValidation)
{
  Write-Host "[3/5] Validating and formatting Terraform code..." -ForegroundColor Green
  Invoke-TerraformValidation
  Write-Host ""
}
else
{
  Write-Host "[3/5] Skipping validation and formatting (--SkipValidation specified)" -ForegroundColor Yellow
  Write-Host ""
}

# Step 4: Terraform Plan
Write-Host "[4/5] Planning Terraform deployment..." -ForegroundColor Green

$planCommand = "terraform plan -out=tfplan"
if ($VarFile -and (Test-Path $VarFile))
{
  $planCommand = "terraform plan -var-file=`"$VarFile`" -out=tfplan"
}

Invoke-CommandWithLogging -Command $planCommand -ExitOnFailure
Write-Host "[Plan] ✓ Terraform plan successful" -ForegroundColor Green
Write-Host ""

# Step 5: Terraform Apply
Write-Host "[5/5] Applying Terraform changes..." -ForegroundColor Green

if (-not (Test-Path -Path 'tfplan'))
{
  Write-Host "ERROR: Terraform plan file 'tfplan' not found." -ForegroundColor Red
  Write-Host "    Ensure a plan has been created by Step 4 or provide the correct plan file." -ForegroundColor Red
  exit 1
}

Invoke-CommandWithLogging -Command "terraform apply `"tfplan`"" -ExitOnFailure
Write-Host "[Apply] ✓ Terraform apply successful" -ForegroundColor Green
Write-Host ""

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✓ Terraform Deployment Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan

