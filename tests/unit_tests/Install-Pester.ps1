# This script ensures that the Pester PowerShell testing module is installed and imported.
# If Pester is not already installed, it will be installed from PowerShell Gallery with -Force flag.
# If Pester is already installed, this script will simply import it for use in the current session.
# Exit code: 0 on success, throws on failure.

[CmdletBinding()]
param (
  [Parameter()]
  [ValidateNotNullOrEmpty()]
  [version] $MinimumVersion = "5.0.0",

  [Parameter()]
  [switch] $Force = $false
)

try
{
  Write-Host "Starting $($MyInvocation.MyCommand.Name) script"

  $moduleName = "Pester"
  Write-Host "Ensuring module '$moduleName' is available (minimum version: $MinimumVersion)"

  $installedModule = Get-Module -Name $moduleName -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1

  if ($null -eq $installedModule)
  {
    Write-Host "Module '$moduleName' is not installed. Installing from PowerShell Gallery..."
    Install-Module -Name $moduleName -MinimumVersion $MinimumVersion -Force:$Force -Confirm:$false
    Write-Host "Successfully installed module '$moduleName'"
  }
  else
  {
    Write-Host "Module '$moduleName' is already installed (version: $($installedModule.Version))"

    if ($installedModule.Version -lt $MinimumVersion)
    {
      Write-Host "##[warning]Installed version ($($installedModule.Version)) is below minimum required version ($MinimumVersion). Updating..."
      Update-Module -Name $moduleName -Force:$Force -Confirm:$false
      Write-Host "Successfully updated module '$moduleName'"
    }
  }

  Write-Host "Importing module '$moduleName' into current session..."
  Import-Module -Name $moduleName -MinimumVersion $MinimumVersion -Force:$Force -PassThru | Out-Null
  Write-Host "Successfully imported module '$moduleName'"

  Write-Host "Script completed: module is ready for use."
}
catch
{
  Write-Host "##[error]Script failed: $_"
  throw
}
