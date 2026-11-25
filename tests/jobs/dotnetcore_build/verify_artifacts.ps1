$ErrorActionPreference = 'Stop'

$zip = [IO.Compression.ZipFile]::OpenRead("$env:PIPELINE_WORKSPACE/Sample/publish/SampleApp.zip")
try { if (!$zip.GetEntry('SampleApp.dll')) { throw 'Missing compiled app' } } finally { $zip.Dispose() }
if (!(Test-Path -LiteralPath "$env:PIPELINE_WORKSPACE/Sample/publish/ExpandedApp/SampleApp.dll")) { throw 'Missing unzipped publish output' }
if (!(Get-ChildItem -LiteralPath "$env:PIPELINE_WORKSPACE/Sample/nuget/SdkPackage" -Filter *.nupkg)) { throw 'Missing NuGet package' }
foreach ($name in 'Unit','Integration') {
  $root = "$env:PIPELINE_WORKSPACE/Sample_Reports/dotnetcoretest_$name"
  if (!(Get-ChildItem $root -Filter *.trx -Recurse)) { throw "Missing TRX: $name" }
}
if (!(Get-ChildItem "$env:PIPELINE_WORKSPACE/Sample_Reports" -Filter coverage.cobertura.xml -Recurse)) { throw 'Missing coverage' }
