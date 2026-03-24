# ============================================================================
# TEST FRAMEWORK - UTILITIES
# ============================================================================
# Path resolution and helper functions.

function Get-RepositoryPath
{
  <#
  .SYNOPSIS
    Resolve a path relative to the repository root.
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $RelativePath
  )

  return Join-Path $script:TestState.RepositoryRoot $RelativePath
}

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
