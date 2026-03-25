# ============================================================================
# TEST FRAMEWORK - UTILITIES
# ============================================================================

function Get-AccessToken
{
  <#
  .SYNOPSIS
    Get access token from Azure CLI logged-in context.
  #>
  [CmdletBinding()]
  param()

  Write-Verbose "Retrieving access token from Azure CLI logged-in context..."
  try
  {
    $accessToken = az account get-access-token --query accessToken -o tsv
    if (-not $accessToken)
    {
      throw "Failed to retrieve access token from Azure CLI"
    }
  }
  catch
  {
    throw "Unable to get access token from Azure CLI. Ensure you are logged in with 'az login' and have the required permissions."
  }
  return $accessToken
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
    #Write-Verbose "Configuring Azure DevOps organization: $Organization"
    #az devops configure --defaults organization="https://dev.azure.com/$Organization" --auth-type browser 2> $null
    #Write-Verbose "Azure DevOps organization configured"

    Write-Verbose "Automatic sign-in completed successfully."
  }
  catch
  {
    $errorMessage = $_.Exception.Message
    Write-Verbose "Automatic sign-in failed: $errorMessage"
    Write-Verbose "Remediation: Ensure Azure DevOps CLI is installed and you have internet connectivity"
    throw $errorMessage
  }
}
