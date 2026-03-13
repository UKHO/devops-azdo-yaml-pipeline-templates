# Script to install Pester PowerShell testing module if not already installed
# This script ensures Pester is installed and imported for use in the current session

[CmdletBinding()]
param (
  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [version] $MinimumVersion = "5.0.0",

  [Parameter()]
  [switch] $Force = $false
)

# Import utility module
$utilsPath = Join-Path $PSScriptRoot "Utils-TerraformTools.ps1"
if (-not (Test-Path $utilsPath))
{
  Write-Host "Utility module not found: $utilsPath" -ForegroundColor Red
  exit 1
}
. $utilsPath

# Check for administrator rights
if (-not (Test-AdminRights))
{
  $params = @{
    MinimumVersion = $MinimumVersion
    Force           = $Force
  }
  Request-AdminRights -ScriptPath $MyInvocation.MyCommand.Path -Parameters $params
}

try
{
  Write-Host "Starting $($MyInvocation.MyCommand.Name) script"
  Write-Host ""

  # Use reusable function to install/update/import Pester module
  Invoke-PowerShellModuleInstallation -ModuleName "Pester" -MinimumVersion $MinimumVersion -Force:$Force

  Write-Host ""
  Write-Host "Script completed: module is ready for use." -ForegroundColor Green
}
catch
{
  Write-Host "##[error]Failed to install or import 'Pester': $_" -ForegroundColor Red
  exit 1
}


