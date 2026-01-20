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

Write-Host "Starting $($MyInvocation.MyCommand.Name) script"

$outputFileContent = Get-Content -Path $OutputFileName
Write-Host "##[debug]OutputFile content: $outputFileContent"

$terraformOutputVariables = $outputFileContent | ConvertFrom-Json
Write-Host "Exporting required variables for deployment"

foreach ($outputVariableToExport in $OutputVariablesToExport)
{
  Write-Host "Exporting '$outputVariableToExport' variable from terraform output."

  if ($terraformOutputVariables | Get-Member -Name $outputVariableToExport -MemberType NoteProperty)
  {
    $output = $terraformOutputVariables.$outputVariableToExport.value
    Write-Host "Found variable '$outputVariableToExport' with value: $output"
    Write-Host "##vso[task.setvariable variable=$outputVariableToExport;isoutput=true]$output"
    Write-Host "Exported."
  }
  else
  {
    Write-Host "##[error]Cannot find variable '$outputVariableToExport' inside of '$OutputFileName'"
    Write-Host "Script failed: missing variable."
    throw
  }
}

Write-Host "Script completed: exported outputs."
