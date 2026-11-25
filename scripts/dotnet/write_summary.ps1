$ErrorActionPreference = 'Stop'

$summary = Join-Path $env:DOTNETREPORTS summary.md
$lines = @('### .NET build', "Job status before publication: $env:AGENT_JOBSTATUS")
$entries = @(ConvertFrom-Json $env:PRE_JSON) + @(ConvertFrom-Json $env:POST_JSON)
if (!$entries.Count) { $lines += 'No checks configured' }
foreach ($entry in $entries) {
  $key = "$($entry.Check.ToLowerInvariant())_$($entry.Name)"
  $file = Join-Path $env:DOTNETREPORTS "$key.txt"
  $status = if (Test-Path -LiteralPath $file -PathType Leaf) { Get-Content -LiteralPath $file } else { 'Skipped or unavailable' }
  $lines += "- ${key}: $status"
}
Set-Content -LiteralPath $summary -Value $lines
Write-Host "##vso[task.uploadsummary]$summary"
