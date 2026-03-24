# ============================================================================
# TEST FRAMEWORK - STARTUP VALIDATION
# ============================================================================
# Validates test environment (CLI, authentication, configuration)
# Handles automatic sign-in if needed.

function Test-AzDevOpsCli
{
  <#
  .SYNOPSIS
    Verify that Azure DevOps CLI is installed and available.
  #>
  [CmdletBinding()]
  param()

  try
  {
    $null = az devops --version 2> $null
    return $true
  }
  catch
  {
    return $false
  }
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
  return $LASTEXITCODE -eq 0
}

function Invoke-AutoSignIn
{
  <#
  .SYNOPSIS
    Automatically sign in to Azure and configure Azure DevOps.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $Organization
  )

  try
  {
    Write-Verbose "Starting automatic sign-in process..."
    Write-Verbose "Organization: $Organization"

    # Verify Azure DevOps CLI is installed
    Write-Verbose "Checking for Azure DevOps CLI (az devops)..."
    $installed = az extension list --output json 2> $null | ConvertFrom-Json | Where-Object { $_.name -eq 'azure-devops' }

    if ($null -eq $installed)
    {
      throw "Azure DevOps CLI is not installed. Install with: az extension add --name azure-devops"
    }
    Write-Verbose "Azure DevOps CLI available"

    # Check if user is already signed in
    Write-Verbose "Checking current authentication status..."
    $currentUser = az account show --output json 2> $null | ConvertFrom-Json
    if ($null -eq $currentUser)
    {
      Write-Host "  ↳ Not signed in, launching browser for authentication..." -ForegroundColor Cyan
      Write-Verbose "User not signed in, initiating interactive sign-in with device code..."
      az login --use-device-code | Out-Null
      Write-Verbose "Successfully signed in to Azure"
      Write-Host "  ✓ Signed in successfully" -ForegroundColor Green
    }
    else
    {
      Write-Verbose "User already signed in: $( $currentUser.user.name )"
    }

    # Configure Azure DevOps organization default
    Write-Verbose "Configuring Azure DevOps organization: $Organization"
    az devops configure --defaults organization="https://dev.azure.com/$Organization" --auth-type browser 2> $null
    Write-Verbose "Azure DevOps organization configured"

    Write-Verbose "Automatic sign-in completed successfully."
    return $true
  }
  catch
  {
    $errorMessage = $_.Exception.Message
    Write-Verbose "Automatic sign-in failed: $errorMessage"
    Write-Verbose "Remediation: Ensure Azure DevOps CLI is installed and you have internet connectivity"
    throw $errorMessage
  }
}

function Test-AzDOConfigurationValues
{
  <#
  .SYNOPSIS
    Verify that all required configuration parameters are valid.
  #>
  [CmdletBinding()]
  param()

  $config = $script:TestState.AzDO

  return (
  -not [string]::IsNullOrWhiteSpace($config.Organization) -and
    -not [string]::IsNullOrWhiteSpace($config.Project) -and
    $null -ne $config.PipelineId -and
    $config.PipelineId -gt 0
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

  # Validate Azure DevOps CLI
  Write-Host -NoNewline "  ✓ Azure DevOps CLI... "
  if (-not (Test-AzDevOpsCli))
  {
    Write-Host "FAILED" -ForegroundColor Red
    $validationErrors += "Azure DevOps CLI is not installed or not available in PATH. Install with: az extension add --name azure-devops"
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
    $validationErrors += "User is not authenticated with Azure"
    $allValidationsPassed = $false

    # Attempt auto sign-in
    Write-Host "  ↳ Attempting automatic sign-in..." -ForegroundColor Cyan
    try
    {
      Invoke-AutoSignIn -Organization $script:TestState.AzDO.Organization
      Write-Host "  ✓ Automatic sign-in successful" -ForegroundColor Green
      $allValidationsPassed = $true
      $validationErrors = $validationErrors | Where-Object { $_ -notmatch "not authenticated" }
    }
    catch
    {
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
  1. Install Azure DevOps CLI: az extension add --name azure-devops
  2. Authenticate with Azure: az login
  3. Update Config.ps1 with correct Organization, Project, and PipelineId
  4. Run: az devops configure --defaults organization=https://dev.azure.com/your-org

"@

    throw $errorMessage

  }

  Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
  Write-Host "`n"
}

