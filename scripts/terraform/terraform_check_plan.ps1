param (
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $VerificationMode,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $TerraformOutputFileName
)

Write-Host "Starting terraform_check_plan.ps1 script"
Write-Host "Checking if Terraform output file exists: $TerraformOutputFileName"

if ($( Test-Path -Path $TerraformOutputFileName ) -eq $false)
{
  Write-Host "##[error]Terraform Output File '$TerraformOutputFileName' was not created."
  Write-Host "Script completed: output file missing."
}
else
{
  Write-Host "Terraform output file found. Reading contents."
  $terraformOutputFile = Get-Content -Path $TerraformOutputFileName

  if ($terraformOutputFile -match "no changes")
  {
    Write-Host "Terraform plan indicates no changes."
    Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]false"
    Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]false"
    Write-Host "Script completed: no changes detected."
  }
  else
  {
    Write-Host "Terraform plan indicates changes."
    if ($VerificationMode -eq "VerifyOnDestroy")
    {
      Write-Host "VerificationMode: VerifyOnDestroy"
      $numberOfOccurancesToIndicateDeletionOfResources = 2
      $totalDestroyLines = ($terraformOutputFile |
        Select-String -Pattern "destroy" -CaseSensitive |
        Where-Object { $_ -ne "" }).length

      Write-Host "Number of destroy lines: $totalDestroyLines"
      if ($totalDestroyLines -ge $numberOfOccurancesToIndicateDeletionOfResources)
      {
        Write-Host "#[warning]Resources will be destroyed. Manual verification required."
        Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]true"
        Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]true"
      }
    }
    elseif ($VerificationMode -eq "VerifyOnAny")
    {
      Write-Host "VerificationMode: VerifyOnAny"
      Write-Host "#[warning]Resources will be added, removed, or changed. Manual verification required."
      Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]true"
      Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]true"
    }
    else
    {
      Write-Host "VerificationMode: VerifyDisabled"
      Write-Host "Manual verification will be skipped."
      Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]false"
      Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]true"
    }
    Write-Host "Script completed: changes detected."
  }
}
