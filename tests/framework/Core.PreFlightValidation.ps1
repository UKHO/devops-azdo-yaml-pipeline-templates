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

  # Fast path: a valid token is already cached for this session, so the CLI and
  # authentication checks have already passed. Only re-check configuration.
  if ((Get-CachedAccessToken) -and (Test-AzDOConfigurationValues))
  {
    Write-Host "Pre-flight validation: OK (cached session token)" -ForegroundColor DarkGray
    return
  }

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

  # Validate target branch (a detached HEAD outside Azure Pipelines resolves to 'HEAD')
  Write-Host -NoNewline "  ✓ Target branch... "
  if ([string]::IsNullOrWhiteSpace($script:TestState.TargetBranch) -or $script:TestState.TargetBranch -eq 'HEAD')
  {
    Write-Host "FAILED" -ForegroundColor Red
    $validationErrors += "Could not determine the target branch (got '$( $script:TestState.TargetBranch )'). Check out a branch, or set BUILD_SOURCEBRANCH."
    $allValidationsPassed = $false
  }
  else
  {
    Write-Host "$( $script:TestState.TargetBranch )" -ForegroundColor Green
  }

  if ($env:SYSTEM_ACCESSTOKEN)
  {
    # Azure Pipelines: the job access token is used directly; no Azure CLI needed
    Write-Host -NoNewline "  ✓ Azure DevOps authentication... "
    Write-Host "OK (System.AccessToken)" -ForegroundColor Green
  }
  else
  {
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
    $authenticated = $false
    try
    {
      # Acquiring the token proves authentication and caches it for later use
      $null = Get-AccessToken
      $authenticated = $true
    }
    catch
    {
      Write-Verbose "Token acquisition failed: $_"
    }
    if (-not $authenticated)
    {
      Write-Host "FAILED" -ForegroundColor Red
      try
      {
        Write-Host "  ↳ Attempting automatic sign-in..." -ForegroundColor Cyan
        Invoke-AutoSignIn -Organization $script:TestState.AzDO.Organization
        $null = Get-AccessToken
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

