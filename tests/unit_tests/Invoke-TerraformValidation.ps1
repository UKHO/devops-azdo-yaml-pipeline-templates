# Script for running validation checks (fmt, validate, tflint) on terraform_azdo
# No authentication required for validation

# Function to run a command and handle exit codes
function Invoke-Command-WithLogging
{
  param(
    [Parameter(Mandatory = $true)]
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
Invoke-Command-WithLogging -Command $command -ExitOnFailure

# Terraform fmt
$command = "terraform fmt -recursive"
Invoke-Command-WithLogging -Command $command

# Tfsort
$command = "tfsort ."
Invoke-Command-WithLogging -Command $command

# Terraform validate
$command = "terraform validate"
Invoke-Command-WithLogging -Command $command -ExitOnFailure

# Run TFLint
$command = "tflint --config=`"$repositoryRoot/.tflint.hcl`""
Invoke-Command-WithLogging -Command $command

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Validation checks complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan

