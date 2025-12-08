param (
  [Parameter(Mandatory,
    HelpMessage = "Specify the Terraform output variables to export, separated by spaces.")]
  [ValidateNotNullOrEmpty()]
  [string[]] $OutputVariablesToExport,

  [Parameter(Mandatory,
    HelpMessage = "Path to the Terraform output file for extracting the output variables.")]
  [ValidateScript(
    { Test-Path -Path $_ -PathType Leaf },
    ErrorMessage = '"{0}" cannot be found.'
  )]
  [string] $OutputFileName
)

Write-Host "Starting terraform_export_outputs.ps1 script"

$terraformOutputVariables = Get-Content -Path $OutputFileName | ConvertFrom-Json
Write-Output "Exporting required variables for deployment"

foreach ($outputVariableToExport in $OutputVariablesToExport)
{
  Write-Host "Exporting '$outputVariableToExport' variable from terraform output."

  if ( $terraformOutputVariables.ContainsKey($outputVariableToExport))
  {
    $output = $terraformOutputVariables.$outputVariableToExport.value
    Write-Host "Found variable '$outputVariableToExport' with value: $output"
    Write-Host "##vso[task.setvariable variable=$outputVariableToExport;isoutput=true]$output"
    Write-Host "Exported."
  }
  else
  {
    Write-Host "##[error]Cannot find variable '$outputVariableToExport' inside of '$OutputFilePath'"
    Write-Host "Script failed: missing variable."
    throw
  }
}

Write-Host "Script completed: exported outputs."
