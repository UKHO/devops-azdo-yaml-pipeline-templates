#Requires -Version 5.1
<#
.SYNOPSIS
    Runs the complete CI/CD deployment pipeline for the devops-alz-compliant-modules CICD folder.

.DESCRIPTION
    This script performs the following operations:
    1. Authenticates to Azure
    2. Initializes Terraform with backend configuration
    3. Validates and formats the Terraform code
    4. Plans the Terraform deployment
    5. Applies the Terraform changes

.PARAMETER TenantId
    The Azure tenant ID to authenticate against. Default is the UKHO tenant.

.PARAMETER SkipValidation
    If specified, skips the terraform validate and tflint steps.

.PARAMETER SkipPlan
    If specified, skips the terraform plan step and goes directly to apply (requires existing tfplan file).

.EXAMPLE
    .\run-cicd-deployment.ps1

.EXAMPLE
    .\run-cicd-deployment.ps1 -SkipValidation

#>

param(
[string]$TenantId = "",
[string]$ResourceGroupName = "",
[string]$SubscriptionId = "",
[switch]$SkipValidation,
[switch]$SkipPlan
)

# Set strict error handling
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Current Directory: $(Get-Location)" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "CI/CD Deployment Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Azure Authentication
Write-Host "Checking for existing Azure token..."
$existingToken = $null
try
{
  # Try to get an existing token without logging in
  $existingToken = az account get-access-token --resource "https://storage.azure.com/" 2>$null
}
catch
{
  # No existing token
  $existingToken = $null
}

if (-not $existingToken)
{
  Write-Host "No valid token found. Logging in to tenant: $TenantId"
  az login --tenant $TenantId --use-device-code
}
else
{
  Write-Host "✓ Valid token already exists, skipping login" -ForegroundColor Yellow
}

Write-Host "Verifying access token for Azure Storage..."
az account get-access-token --resource "https://storage.azure.com/" | Out-Null

Write-Host "Displaying current account..."
az account show --output table

Write-Host "✓ Azure authentication successful" -ForegroundColor Green
Write-Host ""

# Step 2: Terraform Initialization
Write-Host "[2/6] Initializing Terraform..." -ForegroundColor Green
Write-Host "Running terraform init with backend configuration..."
terraform init -migrate-state `
    -backend-config="key=cicd.tfstate" `
    -backend-config="container_name=tfstate-devops-azdo-yaml-pipeline-templates" `
    -backend-config="storage_account_name=devopschapdevsa" `
    -backend-config="resource_group_name=$ResourceGroupName" `
    -backend-config="subscription_id=$SubscriptionId" `
    -backend-config="use_azuread_auth=true"

Write-Host "✓ Terraform initialization successful" -ForegroundColor Green
Write-Host ""

# Step 3: Validation and Formatting
if (-not $SkipValidation)
{
  Write-Host "[3/6] Validating and formatting Terraform code..." -ForegroundColor Green

  Write-Host "Running terraform validate..."
  terraform validate

  Write-Host "Running terraform fmt..."
  terraform fmt

  Write-Host "✓ Validation and formatting successful" -ForegroundColor Green
  Write-Host ""
}
else
{
  Write-Host "[3/6] Skipping validation and formatting (--SkipValidation specified)" -ForegroundColor Yellow
  Write-Host ""
}

# Step 4: Terraform Plan
if (-not $SkipPlan)
{
  Write-Host "[4/6] Planning Terraform deployment..." -ForegroundColor Green

  Write-Host "Running terraform plan..." -ForegroundColor Green
  Write-Host "Current Location: $(Get-Location)"
  Get-ChildItem | Write-Host
  Write-Host "terraform plan -var-file=`"$scriptDir\ukho.tfvars`" -out tfplan"
  terraform plan -var-file="$scriptDir\ukho.tfvars" -out tfplan
  Write-Host "✓ Terraform plan successful" -ForegroundColor Green
  Write-Host ""
}
else
{
  Write-Host "[4/6] Skipping terraform plan (--SkipPlan specified)" -ForegroundColor Yellow
  Write-Host ""
}


# Step 5: Validation of Plan

Write-Host "[5/6] Confirmation..." -ForegroundColor Green
$confirmation = Read-Host -Prompt "Are you happy with the plan? (yes to continue)"
if ($confirmation -ne "yes")
{
  Write-Host "✗ Deployment cancelled by user." -ForegroundColor Red
  exit 1
}

# Step 6: Terraform Apply
Write-Host "[6/6] Applying Terraform changes..." -ForegroundColor Green
Write-Host "Running terraform apply..."
if (Test-Path -Path 'tfplan')
{
  terraform apply "tfplan"
  Write-Host "✓ Terraform apply successful" -ForegroundColor Green
  Write-Host ""
}
else
{
  Write-Host "✗ Terraform plan file 'tfplan' not found." -ForegroundColor Red
  Write-Host "    Ensure a plan has been created (e.g., run without --SkipPlan) or provide the correct plan file." -ForegroundColor Red
  exit 1
}
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "✓ CI/CD Deployment Complete!" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
