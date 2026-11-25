# Direct integration test: pwsh -NoProfile -File tests/jobs/dotnet_build/test_scripts.ps1
# Uses the same .NET SDK and fixture dependencies as the pipeline; no Azure DevOps or Pester required.
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path
$scripts = Join-Path $repo scripts/dotnet
$workspace = (New-Item -ItemType Directory -Path (Join-Path ([IO.Path]::GetTempPath()) ([guid]::NewGuid()))).FullName
$fixture = Join-Path $repo tests/shared_resources/dotnet
function Invoke-Step($name, [int]$expectedCode = 0) {
  & pwsh -NoProfile -File (Join-Path $scripts "$name.ps1")
  if ($LASTEXITCODE -ne $expectedCode) { throw "$name exited $LASTEXITCODE; expected $expectedCode" }
}
Push-Location $workspace
try {
  $src = New-Item -ItemType Directory 'sample source'
  Copy-Item (Join-Path $repo .editorconfig) $src
  Copy-Item (Join-Path $fixture Sample.sln),(Join-Path $fixture global.json) $src
  foreach ($project in 'SampleApp','SampleTests') {
    $dest = New-Item -ItemType Directory (Join-Path $src $project)
    Get-ChildItem (Join-Path $fixture $project) -File | Where-Object Extension -in '.cs','.csproj' | Copy-Item -Destination $dest
  }
  Set-Location $src
  $env:PIPELINE_WORKSPACE = $workspace
  $env:DOTNETREPORTS = Join-Path $workspace Sample_Reports
  $env:DOTNETPACKAGES = Join-Path $workspace Sample
  $env:DOTNETTARGET = Join-Path $src Sample.sln
  $env:DOTNETCONFIGURATION = 'Release'
  $env:PRE_JSON = '[]'
  $env:POST_JSON = '[]'
  $env:CONFIG_JSON = '{"RelativePathToSolution":"../outside.sln"}'
  Invoke-Step validate_inputs 1
  $env:CONFIG_JSON = '{"RelativePathToSolution":"Sample.sln"}'
  Invoke-Step validate_inputs
  $env:EXPECTED = (Get-Content global.json -Raw | ConvertFrom-Json).sdk.version
  Invoke-Step verify_sdk
  $env:RESTORE_JSON = '{}'
  Invoke-Step restore
  $env:INSTANCE = 'dotnetformat_'
  Invoke-Step check_format
  Invoke-Step build
  $env:TEST_PROJECT = $env:DOTNETTARGET
  foreach ($case in 'Unit','Integration','Missing') {
    $env:TEST_FILTER = "TestCategory=$case"
    $env:INSTANCE = "dotnettest_$case"
    $env:COVERAGE = ($case -eq 'Unit').ToString()
    $env:WARN = ($case -eq 'Missing').ToString()
    Invoke-Step check_tests ([int]($case -eq 'Missing'))
  }
  $env:PACKAGES_JSON = '[{"Type":"Publish","Project":"SampleApp/SampleApp.csproj"}]'
  Invoke-Step package
  Invoke-Step write_summary
  $summary = Join-Path $env:DOTNETREPORTS summary.md
  if ((Get-Content $summary -Raw) -notmatch 'No checks configured') { throw 'Missing empty-check summary' }
  $env:POST_JSON = '[{"Check":"DotNetTest","Name":"Missing"}]'
  Invoke-Step write_summary
  if ((Get-Content $summary -Raw) -notmatch 'Warned \(0 executed\)') { throw 'Missing warning verdict' }
  & (Join-Path $PSScriptRoot verify_artifacts.ps1)
  Write-Host 'Script behaviour and package/report layout verified.'
} finally {
  Pop-Location
  Remove-Item -LiteralPath $workspace -Recurse -Force
}
