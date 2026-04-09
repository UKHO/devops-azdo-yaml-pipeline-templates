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

# Check if diagnostics are enabled in the pipeline
$isDebugMode = $env:SYSTEM_DEBUG -eq 'true'

# Helper function for debug logging
function Write-DebugLog {
  param([string]$Message)
  if ($isDebugMode) {
    Write-Host "##[debug]$Message"
  }
}

# Read the entire file as a single string to preserve JSON structure
$outputFileContent = Get-Content -Path $OutputFileName -Raw

# Validate file content is not empty
if ([string]::IsNullOrWhiteSpace($outputFileContent))
{
  Write-Host "##[error]Output file '$OutputFileName' is empty or contains only whitespace"
  throw "Cannot parse empty JSON content"
}

Write-DebugLog "OutputFile content: $outputFileContent"

# Parse JSON with better error handling
try
{
  $terraformOutputVariables = $outputFileContent | ConvertFrom-Json
}
catch
{
  Write-Host "##[error]Failed to parse JSON from '$OutputFileName'"
  Write-Host "##[error]Error: $($_.Exception.Message)"
  throw
}

Write-Host "Exporting required variables for deployment"

foreach ($outputVariableToExport in $OutputVariablesToExport)
{
  Write-Host "Exporting '$outputVariableToExport' variable from terraform output."

  if ($terraformOutputVariables | Get-Member -Name $outputVariableToExport -MemberType NoteProperty)
  {
    $outputVariable = $terraformOutputVariables.$outputVariableToExport
    $output = $outputVariable.value
    $isSensitive = $outputVariable.sensitive

    # Mask sensitive values in logging
    $displayValue = if ($isSensitive) { "***REDACTED***" } else { $output }
    Write-Host "Found variable '$outputVariableToExport' with value: $displayValue"

    # Export the actual value (including sensitive values)
    Write-Host "##vso[task.setvariable variable=$outputVariableToExport;isoutput=true;issecret=$isSensitive]$output"
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
