# Exercises repository-specific policy; native SDK/CLI/archive tasks are covered by build_test.yml.
$ErrorActionPreference = 'Stop'
$scripts = (Resolve-Path (Join-Path $PSScriptRoot '../../../scripts/dotnet')).Path
$workspace = (New-Item -ItemType Directory (Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid()))).FullName
function Invoke-Step($name, [int]$expectedCode = 0) {
  & pwsh -NoProfile -File (Join-Path $scripts "$name.ps1")
  if ($LASTEXITCODE -ne $expectedCode) { throw "$name exited $LASTEXITCODE; expected $expectedCode" }
}
Push-Location $workspace
try {
  $env:DOTNETREPORTS = Join-Path $workspace reports
  $env:PRE_JSON = '[]'
  $env:POST_JSON = '[]'
  $env:CONFIG_JSON = '{"RelativePathToSolution":"../outside.sln"}'
  Invoke-Step validate_inputs 1
  Set-Content sample.sln -Value ''
  $env:EXPECTED = dotnet --version
  $env:CONFIG_JSON = @{ RelativePathToSolution='sample.sln'; DotNetSdk=@{ Version=$env:EXPECTED } } | ConvertTo-Json
  Invoke-Step validate_inputs
  Invoke-Step verify_sdk
  $env:PACKAGE_PROJECT = 'src/My.Library.csproj'
  if ((Invoke-Step resolve_package_name) -notmatch 'DotNetDefaultPackageName\]My\.Library$') { throw 'Incorrect derived package name' }
  $env:INSTANCE = 'dotnettest_Unit'
  $results = New-Item -ItemType Directory (Join-Path $env:DOTNETREPORTS $env:INSTANCE)
  $trx = Join-Path $results unit.trx
  Set-Content $trx '<TestRun><ResultSummary><Counters executed="0"/></ResultSummary></TestRun>'
  Invoke-Step validate_test_evidence 1
  Set-Content $trx '<TestRun><ResultSummary><Counters executed="2"/></ResultSummary></TestRun>'
  Invoke-Step validate_test_evidence
  Invoke-Step write_summary
  $summary = Join-Path $env:DOTNETREPORTS summary.md
  if ((Get-Content $summary -Raw) -notmatch 'No checks configured') { throw 'Missing empty-check summary' }
  $env:POST_JSON = '[{"Check":"DotNetTest","Name":"Unit"}]'
  foreach ($case in @(@('succeeded','succeeded','Passed'), @('failed','skipped','Failed'), @('succeededWithIssues','succeeded','Warned'), @('skipped','skipped','Skipped'))) {
    & (Join-Path $scripts write_summary.ps1) -Records @([pscustomobject]@{ refName='PostTest_Unit'; result=$case[0] }, [pscustomobject]@{ refName='PostEvidence_Unit'; result=$case[1] })
    if ((Get-Content $summary -Raw) -notmatch "Unit: $($case[2])") { throw "Wrong summary: $case" }
  }
  Write-Host 'Script policy tests passed.'
} finally {
  Pop-Location
  Remove-Item -LiteralPath $workspace -Recurse -Force
}
