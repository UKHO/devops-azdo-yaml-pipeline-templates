# Utility module for Terraform tools installation (Windows only)

function Test-CommandExists
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$CommandName
  )

  $command = Get-Command $CommandName -ErrorAction SilentlyContinue
  return $null -ne $command
}

function Invoke-ToolInstallation
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$ToolName,
    [Parameter(Mandatory = $true)]
    [string]$ChocoPackageName,
    [Parameter(Mandatory = $true)]
    [string]$WindowsDownloadUrl,
    [Parameter(Mandatory = $true)]
    [string]$ExecutableName
  )

  Write-Host "Checking for $ToolName..." -ForegroundColor Yellow

  if (Test-CommandExists -CommandName $ToolName)
  {
    Write-Host "$ToolName is already installed" -ForegroundColor Green
    try
    {
      $version = Invoke-Expression "$ToolName --version"
      Write-Host "Version: $version" -ForegroundColor Gray
    }
    catch
    {
      Write-Host "Could not retrieve version info" -ForegroundColor Gray
    }
    return $true
  }

  Write-Host "$ToolName is not installed. Installing..." -ForegroundColor Yellow
  try
  {
    Install-WindowsTool -ToolName $ToolName -ChocoPackageName $ChocoPackageName -DownloadUrl $WindowsDownloadUrl -ExecutableName $ExecutableName
    Write-Host "$ToolName installed successfully!" -ForegroundColor Green
    return $true
  }
  catch
  {
    Write-Host "Failed to install $ToolName : $_" -ForegroundColor Red
    exit 1
  }
}

function Install-WindowsTool
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$ToolName,
    [Parameter(Mandatory = $true)]
    [string]$ChocoPackageName,
    [Parameter(Mandatory = $true)]
    [string]$DownloadUrl,
    [Parameter(Mandatory = $true)]
    [string]$ExecutableName
  )

  if (Get-Command choco -ErrorAction SilentlyContinue)
  {
    Write-Host "Installing $ToolName via Chocolatey..." -ForegroundColor Gray
    choco install $ChocoPackageName -y

    # Try to find the installation path from Chocolatey
    $chocoPath = Join-Path $env:ProgramData "chocolatey\lib\$ChocoPackageName"
    if (Test-Path $chocoPath)
    {
      Write-Host "Installation location: $chocoPath" -ForegroundColor Cyan
    }
  }
  else
  {
    Write-Host "Installing $ToolName via direct download..." -ForegroundColor Gray
    $tempDir = Join-Path $env:TEMP "${ToolName}_install"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    $fileName = Split-Path -Leaf $DownloadUrl
    $filePath = Join-Path $tempDir $fileName

    Invoke-WebRequest -Uri $DownloadUrl -OutFile $filePath

    if ($fileName -like "*.zip")
    {
      Expand-Archive -Path $filePath -DestinationPath $tempDir -Force
    }
    elseif ($fileName -like "*.tar.gz")
    {
      tar -xzf $filePath -C $tempDir
    }

    $programFilesPath = Join-Path $env:ProgramFiles $ToolName
    New-Item -ItemType Directory -Path $programFilesPath -Force | Out-Null
    Copy-Item -Path "$tempDir\$ExecutableName" -Destination $programFilesPath -Force

    # Add to PATH if not already there
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if (-not $currentPath.Contains($programFilesPath))
    {
      [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$programFilesPath", "User")
      Write-Host "Added $programFilesPath to PATH" -ForegroundColor Gray
    }

    Write-Host "Installation location: $programFilesPath" -ForegroundColor Cyan

    Remove-Item -Path $tempDir -Recurse -Force
  }
}

function Invoke-PowerShellModuleInstallation
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleName,
    [Parameter(Mandatory = $true)]
    [version]$MinimumVersion,
    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
  )

  Write-Host "Ensuring module '$ModuleName' is available (minimum version: $MinimumVersion)"

  $installedModule = Get-Module -Name $ModuleName -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1

  if ($null -eq $installedModule)
  {
    Write-Host "Module '$ModuleName' is not installed. Installing from PowerShell Gallery..."
    Install-Module -Name $ModuleName -MinimumVersion $MinimumVersion -Force:$Force -Confirm:$false
    Write-Host "Successfully installed module '$ModuleName'" -ForegroundColor Green
  }
  else
  {
    Write-Host "Module '$ModuleName' is already installed (version: $($installedModule.Version))" -ForegroundColor Green

    if ($installedModule.Version -lt $MinimumVersion)
    {
      Write-Host "##[warning]Installed version ($($installedModule.Version)) is below minimum required version ($MinimumVersion). Updating..." -ForegroundColor Yellow
      Update-Module -Name $ModuleName -Force:$Force -Confirm:$false
      Write-Host "Successfully updated module '$ModuleName'" -ForegroundColor Green
    }
  }

  Write-Host "Importing module '$ModuleName' into current session..."
  Import-Module -Name $ModuleName -MinimumVersion $MinimumVersion -Force:$Force -PassThru | Out-Null
  Write-Host "Successfully imported module '$ModuleName'" -ForegroundColor Green

  # Display installation path
  $moduleInfo = Get-Module -Name $ModuleName -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1
  if ($moduleInfo)
  {
    Write-Host "Installation location: $($moduleInfo.ModuleBase)" -ForegroundColor Cyan
  }
}

function Test-AdminRights
{
  $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdminRights
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptPath,
    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters
  )

  Write-Host "This script requires administrator rights." -ForegroundColor Yellow
  $response = Read-Host "Do you want to run this script with administrator rights? (Y/N)"

  if ($response -eq "Y" -or $response -eq "y")
  {
    Write-Host "Requesting administrator rights..." -ForegroundColor Gray

    # Build parameter string for the elevated script
    $paramString = ""
    if ($Parameters -and $Parameters.Count -gt 0)
    {
      $paramParts = @()
      foreach ($key in $Parameters.Keys)
      {
        if ($Parameters[$key] -is [bool])
        {
          $paramParts += "-$key"
        }
        else
        {
          $paramParts += "-$key '$($Parameters[$key])'"
        }
      }
      $paramString = " $($paramParts -join ' ')"
    }

    $elevatedCommand = "& '$ScriptPath'$paramString"
    Start-Process pwsh -ArgumentList "-NoExit", "-Command", $elevatedCommand -Verb RunAs
    exit 0
  }
  else
  {
    Write-Host "Script requires administrator rights to proceed. Exiting..." -ForegroundColor Red
    exit 1
  }
}
