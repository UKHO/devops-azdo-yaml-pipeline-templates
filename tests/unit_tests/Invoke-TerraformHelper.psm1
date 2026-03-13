#Requires -Version 5.1
<#
.SYNOPSIS
    Helper module for Terraform CI/CD operations containing shared functions.

.DESCRIPTION
    Provides common functionality used across multiple Terraform deployment and validation scripts.
    This module centralizes logging, command execution, and authentication logic to reduce duplication.

#>

# Function to run a command and handle exit codes
function Invoke-CommandWithLogging
{
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [switch]$ExitOnFailure
  )

  Write-Host "Running: $Command" -ForegroundColor Yellow
  Invoke-Expression $Command

  if ($LASTEXITCODE -ne 0)
  {
    if ($ExitOnFailure)
    {
      Write-Host "Command failed: $Command" -ForegroundColor Red
      exit 1
    }
    else
    {
      Write-Host "Command completed with warnings/issues" -ForegroundColor Yellow
    }
  }
}

# Function to authenticate to Azure
function Connect-ToAzure
{
  param(
    [Parameter(Mandatory = $false)]
    [AllowNull()]
    [AllowEmptyString()]
    [guid]$TenantId
  )

  Write-Host "[Authentication] Logging out of any existing Azure sessions..." -ForegroundColor Gray
  az logout 2>$null | Out-Null
  az account clear 2>$null | Out-Null

  Write-Host "[Authentication] Removing cached MSAL tokens..." -ForegroundColor Gray
  Remove-Item "$env:USERPROFILE\.azure\msal_token_cache*" -Force -ErrorAction SilentlyContinue | Out-Null

  if ($TenantId)
  {
    Write-Host "[Authentication] Logging in to tenant: $TenantId" -ForegroundColor Gray
    az login --tenant $TenantId.ToString() --use-device-code
  }
  else
  {
    Write-Host "[Authentication] Logging in with default tenant" -ForegroundColor Gray
    az login --use-device-code
  }

  Write-Host "[Authentication] Verifying access token for Azure Storage..." -ForegroundColor Gray
  az account get-access-token --resource "https://storage.azure.com/" | Out-Null

  Write-Host "[Authentication] Displaying current account..." -ForegroundColor Gray
  az account show --output table

  Write-Host "[Authentication] ✓ Azure authentication successful" -ForegroundColor Green
}

# Function to initialize Terraform with backend configuration
function Initialize-Terraform
{
  param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({
      # Allow empty hashtable (no backend config)
      if ($_.Count -eq 0) {
        return $true
      }

      # If hashtable has values, validate all values are not null or whitespace
      foreach ($key in $_.Keys) {
        if ([string]::IsNullOrWhiteSpace($_.[$key])) {
          throw "BackendConfig['$key'] value cannot be null or empty"
        }
      }

      return $true
    })]
    [hashtable]$BackendConfig
  )

  Write-Host "[Terraform Init] Running terraform init with backend configuration..." -ForegroundColor Gray

  $initCommand = "terraform init -migrate-state"
  foreach ($key in $BackendConfig.Keys)
  {
    $initCommand += " -backend-config=`"$key=$($BackendConfig[$key])`""
  }

  Invoke-CommandWithLogging -Command $initCommand -ExitOnFailure
  Write-Host "[Terraform Init] ✓ Terraform initialization successful" -ForegroundColor Green
}

# Function to validate and format Terraform code
function Invoke-TerraformValidation
{
  param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({
      if ([string]::IsNullOrWhiteSpace($_)) { return $true }  # Allow null/empty for default tflint config
      if (-not (Test-Path -Path $_ -PathType Leaf)) {
        throw "TflintConfigPath '$_' does not exist or is not a file"
      }
      return $true
    })]
    [string]$TflintConfigPath
  )

  Write-Host "[Validation] Running terraform validate..." -ForegroundColor Gray
  Invoke-CommandWithLogging -Command "terraform validate" -ExitOnFailure

  Write-Host "[Validation] Running tflint..." -ForegroundColor Gray
  $tflintCommand = "tflint"
  if ($TflintConfigPath)
  {
    $tflintCommand += " --config=`"$TflintConfigPath`""
  }
  Invoke-CommandWithLogging -Command $tflintCommand

  Write-Host "[Validation] Running terraform fmt..." -ForegroundColor Gray
  Invoke-CommandWithLogging -Command "terraform fmt"

  Write-Host "[Validation] ✓ Validation and formatting successful" -ForegroundColor Green
}

# Export public functions
Export-ModuleMember -Function @(
  'Invoke-CommandWithLogging',
  'Connect-ToAzure',
  'Initialize-Terraform',
  'Invoke-TerraformValidation'
)

