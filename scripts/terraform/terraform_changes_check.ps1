param (
  [Parameter(Mandatory,
    HelpMessage = "Specify the verification mode, whether to verify on destroy actions, any changes, or disable verification.")]
  [ValidateSet("VerifyOnDestroy", "VerifyOnAny", "VerifyDisabled")]
  [string] $VerificationMode,

  [Parameter(Mandatory,
    HelpMessage = "Path to the Terraform plan file to check for changes.")]
  [ValidateScript(
    { Test-Path -Path $_ -PathType Leaf },
    ErrorMessage = '"{0}" cannot be found.'
  )]
  [string] $TerraformPlanFilePath
)

$ErrorActionPreference = 'Stop'
$numberOfDestroyWordsToIndicateDestructiveChange = 2

Write-Host "Starting $($MyInvocation.MyCommand.Name) script"

# Check if diagnostics are enabled in the pipeline
$isDebugMode = $env:SYSTEM_DEBUG -eq 'true'

# Helper function for debug logging
function Write-DebugLog {
  param([string]$Message)
  if ($isDebugMode) {
    Write-Host "##[debug]$Message"
  }
}

# Initialize output variables
$changesNeedManualVerification = $true
$changesNeedApplying = $false

Write-DebugLog "Verification Mode: $VerificationMode"
Write-DebugLog "Terraform Plan File: $TerraformPlanFilePath"

# Read and validate the terraform plan file
try
{
  $terraformPlan = Get-Content -Path $TerraformPlanFilePath -ErrorAction Stop

  if ([string]::IsNullOrWhiteSpace($terraformPlan))
  {
    Write-Host "##[error]Terraform plan file is empty or contains only whitespace"
    throw "Cannot process empty plan file"
  }

  Write-DebugLog "Plan file read successfully"
}
catch
{
  Write-Host "##[error]Failed to read Terraform plan file from '$TerraformPlanFilePath'"
  Write-Host "##[error]Error: $($_.Exception.Message)"
  throw
}

Write-Host "##[group]Analyzing Terraform plan for changes"

# Check if plan has any changes
if (($terraformPlan | Select-String -Pattern "No changes. Your infrastructure matches the configuration." -CaseSensitive).Count -eq 1)
{
  Write-Host "✓ Terraform plan indicates no changes"
  $changesNeedManualVerification = $false
  $changesNeedApplying = $false
  Write-Host "##[endgroup]"
  Write-Host "##vso[task.setvariable variable=ChangesNeedManualVerification;isoutput=true]$changesNeedManualVerification"
  Write-Host "##vso[task.setvariable variable=ChangesNeedApplying;isoutput=true]$changesNeedApplying"
  Write-Host "Script completed successfully: no changes detected"
  return
}

Write-Host "! Terraform plan indicates changes will be made"

# Determine verification requirements based on mode
switch ($VerificationMode)
{
  "VerifyOnDestroy" {
    Write-DebugLog "Processing VerifyOnDestroy mode"

    $destroyCount = ($terraformPlan | Select-String -Pattern "destroy" -CaseSensitive).Count

    Write-DebugLog "Found $destroyCount lines with 'destroy' keyword"

    if ($destroyCount -ge $numberOfDestroyWordsToIndicateDestructiveChange)
    {
      Write-Host "##[warning]Resources will be destroyed. Manual verification is REQUIRED."
      $changesNeedManualVerification = $true
      $changesNeedApplying = $true
    }
    else
    {
      Write-Host "✓ No resources will be destroyed. Proceeding without manual verification."
      $changesNeedManualVerification = $false
      $changesNeedApplying = $true
    }
  }
  "VerifyOnAny" {
    Write-DebugLog "Processing VerifyOnAny mode"
    Write-Host "##[warning]Resources will be added, removed, or changed. Manual verification is REQUIRED."
    $changesNeedManualVerification = $true
    $changesNeedApplying = $true
  }
  "VerifyDisabled" {
    Write-DebugLog "Processing VerifyDisabled mode"
    Write-Host "⊘ Manual verification is DISABLED. Changes will be applied automatically."
    $changesNeedManualVerification = $false
    $changesNeedApplying = $true
  }
}

Write-Host "##[endgroup]"

# Output the decision variables
Write-Host "##[group]Exporting decision variables"
Write-Host "ChangesNeedManualVerification: $changesNeedManualVerification"
Write-Host "ChangesNeedApplying: $changesNeedApplying"
Write-Host "##vso[task.setvariable variable=ChangesNeedManualVerification;isoutput=true]$changesNeedManualVerification"
Write-Host "##vso[task.setvariable variable=ChangesNeedApplying;isoutput=true]$changesNeedApplying"
Write-Host "##[endgroup]"

Write-Host "Script completed successfully: changes detected and evaluated"
