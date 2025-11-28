param (
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $VerificationMode,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $TerraformOutputFileName
)

$changesNeedManualVerification = $true
$changesNeedApplying = $false

Write-Host "Starting terraform_check_plan.ps1 script"
Write-Host "Checking if Terraform output file exists: $TerraformOutputFileName"

if (-not (Test-Path -Path $TerraformOutputFileName))
{
  Write-Host "##[error]erraform Output File '$TerraformOutputFileName' was not created."
  Write-Host "Script completed: output file missing."
  return
}

Write-Host "Terraform output file found. Reading contents."
$terraformOutputFile = Get-Content -Path $TerraformOutputFileName

if ($terraformOutputFile -match "no changes")
{
  Write-Host "Terraform plan indicates no changes."
  $changesNeedManualVerification = $false
  $changesNeedApplying = $false
  Write-Host "Script completed: no changes detected."
  return
}

Write-Host "##[group]Terraform plan indicates changes."
switch ($VerificationMode)
{
  "VerifyOnDestroy" {
    Write-Host "VerificationMode: VerifyOnDestroy"
    $destroyCount = ($terraformOutputFile | Select-String -Pattern "destroy" -CaseSensitive).Count
    Write-Host "Number of destroy lines: $destroyCount"

    if ($destroyCount -ge 2)
    {
      Write-Host "##[warning]Resources will be destroyed. Manual verification required."
      $changesNeedManualVerification = $true
      $changesNeedApplying = $true
    } else
    {
      Write-Host "No resources will be destroyed. Proceeding without manual verification."
      $changesNeedManualVerification = $false
      $changesNeedApplying = $true
    }
  }
  "VerifyOnAny" {
    Write-Host "VerificationMode: VerifyOnAny"
    Write-Host "##[warning]Resources will be added, removed, or changed. Manual verification required."
    $changesNeedManualVerification = $true
    $changesNeedApplying = $true
  }
  default {
    Write-Host "VerificationMode: VerifyDisabled"
    Write-Host "Manual verification will be skipped."
    $changesNeedManualVerification = $false
    $changesNeedApplying = $true
  }
}
Write-Host "##[endgroup]"

Write-Host "##vso[task.setvariable variable=ChangesNeedManualVerification;isoutput=true]$changesNeedManualVerification"
Write-Host "##vso[task.setvariable variable=ChangesNeedApplying;isoutput=true]$changesNeedApplying"

Write-Host "Script completed: changes detected."
