param (
  [Parameter(Mandatory,
    HelpMessage = "Specify the verification mode, whether to verify on destroy actions, any changes, or disable verification.")]
  [ValidateSet("VerifyOnDestroy", "VerifyOnAny", "VerifyDisabled")]
  [string] $VerificationMode,

  [Parameter(Mandatory,
    HelpMessage = "Path to the Terraform plan file to check for changes.")]
  [ValidateScript(
    { -not (Test-Path -Path $_) },
    ErrorMessage = '"{0}" cannot be found.'
  )]
  [string] $TerraformPlanFilePath
)

$changesNeedManualVerification = $true
$changesNeedApplying = $false

Write-Host "Starting terraform_check_plan.ps1 script"
$terraformPlan = Get-Content -Path $TerraformPlanFilePath

if ($terraformPlan -match "no changes")
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
    $destroyCount = ($terraformPlan | Select-String -Pattern "destroy" -CaseSensitive).Count
    Write-Host "Number of destroy lines: $destroyCount"

    if ($destroyCount -ge 2)
    {
      Write-Host "##[warning]Resources will be destroyed. Manual verification required."
      $changesNeedManualVerification = $true
      $changesNeedApplying = $true
    }
    else
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
