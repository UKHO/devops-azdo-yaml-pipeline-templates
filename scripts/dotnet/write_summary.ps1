# Read native task verdicts rather than guessing from the aggregate job status (which is sticky after a warning).
[CmdletBinding()]
param([object[]]$Records)
$ErrorActionPreference = 'Stop'
$entries = @(ConvertFrom-Json $env:PRE_JSON) + @(ConvertFrom-Json $env:POST_JSON)
if ($entries.Count -and !$PSBoundParameters.ContainsKey('Records') -and $env:SYSTEM_ACCESSTOKEN) {
  $uri = "$($env:SYSTEM_COLLECTIONURI)$($env:SYSTEM_TEAMPROJECTID)/_apis/build/builds/$($env:BUILD_BUILDID)/timeline?api-version=7.1"
  try {
    $timeline = Invoke-RestMethod -Uri $uri -Headers @{ Authorization = "Bearer $env:SYSTEM_ACCESSTOKEN" } -TimeoutSec 15
    $Records = @($timeline.records | Where-Object { $_.parentId -eq $env:SYSTEM_JOBID -and $_.type -eq 'Task' })
  } catch { Write-Warning 'Task timeline unavailable; see the native task results.' }
}
$lines = @('### .NET build', "Job status before publication: $env:AGENT_JOBSTATUS")
if (!$entries.Count) { $lines += 'No checks configured' }
foreach ($entry in $entries) {
  $id = if ($entry.Check -eq 'DotNetFormat') { 'PreFormat_' } else { 'PostTest_' }
  $ids = @("$id$($entry.Name)")
  if ($entry.Check -eq 'DotNetTest') { $ids += "PostEvidence_$($entry.Name)" }
  $results = foreach ($ref in $ids) {
    $record = $Records | Where-Object refName -eq $ref | Select-Object -Last 1
    if ($record.result) { $record.result } else { 'unknown' }
  }
  $status = if ($results -contains 'failed') { 'Failed' } elseif ($results -contains 'canceled') { 'Canceled' } elseif ($results -contains 'unknown') { 'Unavailable' } elseif ($results -contains 'skipped') { 'Skipped' } elseif ($results -contains 'succeededWithIssues') { 'Warned' } elseif (!(@($results | Where-Object { $_ -ne 'succeeded' }).Count)) { 'Passed' } else { 'Unavailable' }
  $lines += "- $($entry.Check) $($entry.Name): $status"
}
$summary = Join-Path $env:DOTNETREPORTS summary.md
Set-Content -LiteralPath $summary -Value $lines
Write-Host "##vso[task.uploadsummary]$summary"
