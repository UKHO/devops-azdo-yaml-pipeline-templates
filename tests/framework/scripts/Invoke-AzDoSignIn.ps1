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

try
{
  Write-Verbose "Starting $( $MyInvocation.MyCommand.Name ) script"
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
    Write-Verbose "User not signed in, initiating interactive sign-in..."
    az login --use-device-code | Out-Null
    Write-Verbose "Successfully signed in to Azure"
  }
  else
  {
    Write-Verbose "User already signed in: $( $currentUser.user.name )"
  }

  # Configure Azure DevOps organization default
  Write-Verbose "Configuring Azure DevOps organization: $Organization"
  az devops configure --defaults organization="https://dev.azure.com/$Organization" --auth-type browser 2> $null
  Write-Verbose "Azure DevOps organization configured"

  Write-Verbose "Script completed: Sign-in successful."
}
catch
{
  $errorMessage = $_.Exception.Message

  Write-Error "Azure DevOps sign-in failed: $errorMessage"

  Write-Verbose "Remediation steps:"
  Write-Verbose "1. Ensure Azure DevOps CLI is installed: az extension add --name azure-devops"
  Write-Verbose "2. Check internet connection"
  Write-Verbose "3. Verify organization name: $Organization"

  throw
}

