# This script signs in to Azure DevOps using the CLI if the user is not already signed in.
# Uses interactive sign-in (browser/device code flow) with user context.
# Returns nothing on success. Throws on failure.
#
# See: docs/developers/10-azure-devops-rest-api-pipeline-yaml.md

[CmdletBinding()]
param (
  [Parameter(Mandatory,
    HelpMessage = "Azure DevOps organization name.")]
  [ValidateNotNullOrEmpty()]
  [string] $Organization
)

try {
  Write-Verbose "Starting $($MyInvocation.MyCommand.Name) script"
  Write-Verbose "Organization: $Organization"

  # Verify Azure DevOps CLI is installed
  Write-Verbose "Checking for Azure DevOps CLI (az devops)..."
  try {
    $cliVersion = az devops --version 2>$null
    Write-Verbose "Azure DevOps CLI available"
  }
  catch {
    throw "Azure DevOps CLI is not installed. Install with: az extension add --name azure-devops"
  }

  # Check if user is already signed in
  Write-Verbose "Checking current authentication status..."
  try {
    $currentUser = az account show --output json 2>$null | ConvertFrom-Json
    Write-Verbose "User already signed in: $($currentUser.user.name)"
  }
  catch {
    Write-Verbose "User not signed in, initiating interactive sign-in..."

    try {
      # Sign in with browser/device code flow
      az login --use-device-code | Out-Null
      Write-Verbose "Successfully signed in to Azure"
    }
    catch {
      throw "Failed to authenticate: $($_.Exception.Message)"
    }
  }

  # Configure Azure DevOps organization default
  Write-Verbose "Configuring Azure DevOps organization: $Organization"
  try {
    az devops configure --defaults organization="https://dev.azure.com/$Organization" --auth-type browser 2>$null
    Write-Verbose "Azure DevOps organization configured"
  }
  catch {
    throw "Failed to configure organization: $($_.Exception.Message)"
  }

  Write-Verbose "Script completed: Sign-in successful."
}
catch {
  $errorMessage = $_.Exception.Message

  Write-Error "Azure DevOps sign-in failed: $errorMessage"

  Write-Verbose "Remediation steps:"
  Write-Verbose "1. Ensure Azure DevOps CLI is installed: az extension add --name azure-devops"
  Write-Verbose "2. Check internet connection"
  Write-Verbose "3. Verify organization name: $Organization"

  throw
}

