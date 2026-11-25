$ErrorActionPreference = 'Stop'

$zip = [IO.Compression.ZipFile]::OpenRead("$env:PIPELINE_WORKSPACE/Sample/publish/SampleApp.zip")
try { if (!$zip.GetEntry('SampleApp.dll')) { throw 'Missing compiled app' } } finally { $zip.Dispose() }
foreach ($name in 'Unit','Integration') {
  $root = "$env:PIPELINE_WORKSPACE/Sample_Reports/dotnettest_$name"
  if (!(Get-ChildItem $root -Filter *.trx -Recurse)) { throw "Missing TRX: $name" }
}
if (!(Get-ChildItem "$env:PIPELINE_WORKSPACE/Sample_Reports" -Filter coverage.cobertura.xml -Recurse)) { throw 'Missing coverage' }
