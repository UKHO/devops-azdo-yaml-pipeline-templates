# ============================================================================
# TEST FRAMEWORK - AUTHENTICATION
# ============================================================================


function Get-CachedAccessToken
{
  <#
  .SYNOPSIS
    Return the session-cached access token, or $null if no token is cached.
  #>
  [CmdletBinding()]
  param()

  return $global:AzDOCompileTestTokenCache.accessToken
}

function Get-AccessToken
{
  <#
  .SYNOPSIS
    Get access token from Azure CLI logged-in context.
  .DESCRIPTION
    The token is cached in the global scope for the lifetime of the PowerShell
    session, so that running many test files only invokes the (slow) Azure CLI once.
    Token expiry is not checked; an expired token may cause requests to fail.
  #>
  [CmdletBinding()]
  param()

  if (Get-CachedAccessToken)
  {
    Write-Verbose "Using cached access token"
    return Get-CachedAccessToken
  }

  # Azure Pipelines: use the job access token (System.AccessToken must be mapped
  # into the step's environment as SYSTEM_ACCESSTOKEN). No Azure CLI required.
  if ($env:SYSTEM_ACCESSTOKEN)
  {
    Write-Verbose "Using SYSTEM_ACCESSTOKEN from the pipeline environment"
    return $env:SYSTEM_ACCESSTOKEN
  }

  Write-Verbose "Retrieving access token from Azure CLI logged-in context..."
  try
  {
    $json = az account get-access-token --output json 2> $null
    if ($LASTEXITCODE -ne 0 -or -not $json)
    {
      throw "Failed to retrieve access token from Azure CLI"
    }
    $token = ($json -join "`n") | ConvertFrom-Json
    if (-not $token.accessToken)
    {
      throw "Failed to retrieve access token from Azure CLI"
    }
  } catch
  {
    throw "Unable to get access token from Azure CLI. Ensure you are logged in with 'az login' and have the required permissions."
  }

  $global:AzDOCompileTestTokenCache = $token
  return $token.accessToken
}

function Invoke-AutoSignIn
{
  <#
  .SYNOPSIS
    Automatically sign in to Azure.
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

    # Check if user is already signed in
    Write-Verbose "Checking current authentication status..."
    $currentUser = az account show --output json 2> $null | ConvertFrom-Json
    if ($null -eq $currentUser)
    {
      Write-Host "  ↳ Not signed in, attempting signin.." -ForegroundColor Cyan
      Write-Verbose "User not signed in, initiating interactive sign-in..."
      az login | Out-Null
      Write-Verbose "Successfully signed in to Azure"
      Write-Host "  ✓ Signed in successfully" -ForegroundColor Green
    } else
    {
      Write-Verbose "User already signed in: $( $currentUser.user.name )"
    }

    Write-Verbose "Automatic sign-in completed successfully."
  } catch
  {
    $errorMessage = $_.Exception.Message
    Write-Verbose "Automatic sign-in failed: $errorMessage"
    throw $errorMessage
  }
}
