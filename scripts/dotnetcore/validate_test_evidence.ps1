# VSTest can exit successfully with zero matches. A native test failure is handled by DotNetCoreCLI itself.
$ErrorActionPreference = 'Stop'
$out = Join-Path $env:DOTNETCOREREPORTS $env:INSTANCE
$count = 0
foreach ($trx in (Get-ChildItem -LiteralPath $out -Filter *.trx -Recurse -ErrorAction SilentlyContinue)) {
  $count += [int]([xml](Get-Content -LiteralPath $trx.FullName -Raw)).TestRun.ResultSummary.Counters.executed
}
if (!$count) { throw 'No executed tests in TRX results' }
Write-Host "$count tests executed"
if ($env:COVERAGE -eq 'true' -and !(Get-ChildItem -LiteralPath $out -Filter coverage.cobertura.xml -Recurse)) {
  Write-Warning 'Requested coverage unavailable'
}
