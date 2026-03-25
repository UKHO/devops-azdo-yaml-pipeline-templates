# ============================================================================
# TEST FRAMEWORK - STARTUP VALIDATION
# ============================================================================
# Validates test environment (CLI, authentication, configuration)
# Handles automatic sign-in if needed.

function Test-AzCli
{
  <#
  .SYNOPSIS
    Verify that Azure DevOps CLI is installed and available.
  #>
  [CmdletBinding()]
  param()

  $installed = Get-Command az -ErrorAction SilentlyContinue
  return $null -ne $installed
}

function Test-AzAuthentication
{
  <#
  .SYNOPSIS
    Verify that the user is authenticated with Azure (has az account context loaded).
  #>
  [CmdletBinding()]
  param()

  $output = az account show --output json 2>&1
  return $null -eq $output.Exception
}

function Test-AzDOConfigurationValues
{
  <#
  .SYNOPSIS
    Verify that all required configuration parameters are valid.
  #>
  [CmdletBinding()]
  param()

  $azDO = $script:TestState.AzDO

  return (
  -not [string]::IsNullOrWhiteSpace($azDO.Organization) -and
    -not [string]::IsNullOrWhiteSpace($azDO.Project) -and
    $null -ne $azDO.PipelineId -and
    $azDO.PipelineId -gt 0
  )
}

function Invoke-PreFlightValidation
{
  <#
  .SYNOPSIS
    Perform comprehensive validation of the test framework environment.
  #>
  [CmdletBinding()]
  param()

  if ($script:TestState.SkipValidation)
  {
    Write-Host "⚠️  Pre-flight validation is skipped. Ensure your environment is correctly configured." -ForegroundColor Yellow
    return
  }

  $allValidationsPassed = $true
  $validationErrors = @()

  Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host "PRE-FLIGHT VALIDATION" -ForegroundColor Cyan
  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

  # Validate configuration values
  Write-Host -NoNewline "  ✓ Configuration values... "
  if (-not (Test-AzDOConfigurationValues))
  {
    Write-Host "FAILED" -ForegroundColor Red
    $validationErrors += "Configuration values are invalid or empty (Organization: '$( $script:TestState.AzDO.Organization )', Project: '$( $script:TestState.AzDO.Project )', PipelineId: $( $script:TestState.AzDO.PipelineId ))"
    $allValidationsPassed = $false
  }
  else
  {
    Write-Host "OK" -ForegroundColor Green
  }

  # Validate Az CLI
  Write-Host -NoNewline "  ✓ Az CLI... "
  if (-not (Test-AzCli))
  {
    Write-Host "FAILED" -ForegroundColor Red
    $validationErrors += "Az CLI is not installed or not available in PATH."
    $allValidationsPassed = $false
  }
  else
  {
    Write-Host "OK" -ForegroundColor Green
  }

  Write-Host -NoNewline "  ✓ Azure authentication... "
  if (-not (Test-AzAuthentication))
  {
    Write-Host "FAILED" -ForegroundColor Red
    try
    {
      Write-Host "  ↳ Attempting automatic sign-in..." -ForegroundColor Cyan
      Invoke-AutoSignIn -Organization $script:TestState.AzDO.Organization
      Write-Host "  ✓ Automatic sign-in successful" -ForegroundColor Green
    }
    catch
    {
      $validationErrors += "User is not authenticated with Azure"
      $allValidationsPassed = $false
      Write-Host "  ✗ Automatic sign-in failed: $_" -ForegroundColor Red
    }
  }
  else
  {
    Write-Host "OK" -ForegroundColor Green
  }

  # Handle validation results
  if (-not $allValidationsPassed)
  {
    $errorMessage = @"

❌ PRE-FLIGHT VALIDATION FAILED

$( $validationErrors -join "`n" )

REMEDIATION STEPS:
  1. Install Azure CLI 'az'
  2. Authenticate with Azure: az login
  3. Update Config.ps1 with correct Organization, Project, and PipelineId
"@

    throw $errorMessage

  }

  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host "`n"
}

