param (
  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $RunMode,

  [Parameter(Mandatory)]
  [ValidateNotNullOrEmpty()]
  [string] $TerraformOutputFileName
)

if ($( Test-Path -Path $TerraformOutputFileName ) -eq $false)
{
  Write-Host -ForegroundColor Red "Terraform Output File '$TerraformOutputFileName' was not created. See directory content:"
  Get-ChildItem -File | ForEach-Object { Write-Host $_ }
}
else
{
  $terraformOutputFile = Get-Content -Path $TerraformOutputFileName

  if ($terraformOutputFile -match "no changes")
  {
    Write-Host "Terraform plan indicates no changes"
    Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]false"
    Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]false"
  }
  else
  {
    if ($RunMode -eq "VerifyOnDestroy")
    {
      $numberOfOccurancesToIndicateDeletionOfResources = 2
      $totalDestroyLines = ($terraformOutputFile |
        Select-String -Pattern "destroy" -CaseSensitive |
        Where-Object { $_ -ne "" }).length

      if ($totalDestroyLines -ge $numberOfOccurancesToIndicateDeletionOfResources)
      {
        Write-Host "RunMode set to VerifyOnDestroy and terraform plan indicates resources will be destroyed. Please verify..."
        Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]true"
        Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]true"
      }
    }
    elseif ($RunMode -eq "VerifyOnAny")
    {
      Write-Host "RunMode set to VerifyOnAny and terraform plan indicates resources will be add, removed or changed. Please verify..."
      Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]true"
      Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]true"
    }
    else
    {
      Write-Host "RunMode set to VerifyDisabled and terraform plan indicates resources will be add, removed or changed. Manual verification will be skipped..."
      Write-Host "##vso[task.setvariable variable=needsManualVerification;isoutput=true]false"
      Write-Host "##vso[task.setvariable variable=runApply;isoutput=true]true"
    }
  }
}
