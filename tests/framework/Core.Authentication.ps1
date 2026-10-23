# ============================================================================
# TEST FRAMEWORK - AUTHENTICATION
# ============================================================================

function Get-CachedAccessToken
{
  <#
  .SYNOPSIS
    Return the session-cached access token if it is still valid for at least 5 minutes, otherwise $null.
  #>
  [CmdletBinding()]
  param()

  $cache = $global:AzDOCompileTestTokenCache
  if ($null -ne $cache -and $cache.ExpiresOn -gt [DateTimeOffset]::UtcNow.AddMinutes(5))
  {
    return $cache.AccessToken
  }
  return $null
}

function Get-AccessToken
{
  <#
  .SYNOPSIS
    Get access token from Azure CLI logged-in context.
  .DESCRIPTION
    The token is cached in the global scope for the lifetime of the PowerShell
    session (until 5 minutes before expiry), so that running many test files
    only invokes the (slow) Azure CLI once.
  #>
  [CmdletBinding()]
  param()

  $cached = Get-CachedAccessToken
  if ($cached)
  {
    Write-Verbose "Using cached access token"
    return $cached
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
  }
  catch
  {
    throw "Unable to get access token from Azure CLI. Ensure you are logged in with 'az login' and have the required permissions."
  }

  $expiresOn = [DateTimeOffset]::UtcNow.AddMinutes(30)
  if ($token.expires_on)
  {
    $expiresOn = [DateTimeOffset]::FromUnixTimeSeconds([long]$token.expires_on)
  }
  elseif ($token.expiresOn)
  {
    $expiresOn = [DateTimeOffset]::Parse([string]$token.expiresOn)
  }

  $global:AzDOCompileTestTokenCache = @{
    AccessToken = $token.accessToken
    ExpiresOn = $expiresOn
  }
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
          Write-Host "  ↳ Not signed in, launching browser for authentication..." -ForegroundColor Cyan
          Write-Verbose "User not signed in, initiating interactive sign-in..."
          az login | Out-Null
          Write-Verbose "Successfully signed in to Azure"
          Write-Host "  ✓ Signed in successfully" -ForegroundColor Green
      }
      else
      {
          Write-Verbose "User already signed in: $( $currentUser.user.name )"
      }

      Write-Verbose "Automatic sign-in completed successfully."
  }
  catch
  {
      $errorMessage = $_.Exception.Message
      Write-Verbose "Automatic sign-in failed: $errorMessage"
      throw $errorMessage
  }
}
