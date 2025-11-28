param (
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $VerificationMode,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $TerraformOutputFileName
)

Write-Host "##vso[task.logissue type=info]Starting terraform_check_plan.ps1 script"
Write-Host "##vso[task.logissue type=info]Checking if Terraform output file exists: $TerraformOutputFileName"

if ($( Test-Path -Path $TerraformOutputFileName ) -eq $false)
{
  Write-Host "##vso[task.logissue type=error]Terraform Output File '$TerraformOutputFileName' was not created."
  Write-Host "##vso[task.logissue type=info]Script completed: output file missing."
}
else
{
  Write-Host "##vso[task.logissue type=info]Terraform output file found. Reading contents."
  $terraformOutputFile = Get-Content -Path $TerraformOutputFileName

  if ($terraformOutputFile -match "no changes")
  {
    Write-Host "##vso[task.logissue type=info]Terraform plan indicates no changes."
    Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]false"
    Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]false"
    Write-Host "##vso[task.logissue type=info]Script completed: no changes detected."
  }
  else
  {
    Write-Host "##vso[task.logissue type=info]Terraform plan indicates changes."
    if ($VerificationMode -eq "VerifyOnDestroy")
    {
      Write-Host "##vso[task.logissue type=info]VerificationMode: VerifyOnDestroy"
      $numberOfOccurancesToIndicateDeletionOfResources = 2
      $totalDestroyLines = ($terraformOutputFile |
        Select-String -Pattern "destroy" -CaseSensitive |
        Where-Object { $_ -ne "" }).length

      Write-Host "##vso[task.logissue type=info]Number of destroy lines: $totalDestroyLines"
      if ($totalDestroyLines -ge $numberOfOccurancesToIndicateDeletionOfResources)
      {
        Write-Host "##vso[task.logissue type=warning]Resources will be destroyed. Manual verification required."
        Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]true"
        Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]true"
      }
    }
    elseif ($VerificationMode -eq "VerifyOnAny")
    {
      Write-Host "##vso[task.logissue type=info]VerificationMode: VerifyOnAny"
      Write-Host "##vso[task.logissue type=warning]Resources will be added, removed, or changed. Manual verification required."
      Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]true"
      Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]true"
    }
    else
    {
      Write-Host "##vso[task.logissue type=info]VerificationMode: VerifyDisabled"
      Write-Host "##vso[task.logissue type=info]Manual verification will be skipped."
      Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]false"
      Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]true"
    }
    Write-Host "##vso[task.logissue type=info]Script completed: changes detected."
  }
}
