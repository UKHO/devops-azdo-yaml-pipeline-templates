$ErrorActionPreference = 'Stop'

$out = Join-Path $env:DOTNETREPORTS $env:INSTANCE
$options = @('--no-build', '--no-restore', '-c', $env:DOTNETCONFIGURATION, '--results-directory', $out, '--logger', 'trx')
if ($env:TEST_FILTER) { $options += '--filter', $env:TEST_FILTER }
if ($env:COVERAGE -eq 'true') { $options += '--collect', 'XPlat Code Coverage' }
dotnet test $env:TEST_PROJECT @options
$code = $LASTEXITCODE
$count = 0
foreach ($trx in (Get-ChildItem -LiteralPath $out -Filter *.trx -Recurse -ErrorAction SilentlyContinue)) {
  $count += [int]([xml](Get-Content -LiteralPath $trx.FullName -Raw)).TestRun.ResultSummary.Counters.executed
}
if (!$count) { Write-Warning 'No executed tests in TRX results'; $code = 1 }
if ($env:COVERAGE -eq 'true' -and !(Get-ChildItem -LiteralPath $out -Filter coverage.cobertura.xml -Recurse -ErrorAction SilentlyContinue)) { Write-Warning 'Requested coverage unavailable' }
$result = if (!$code) { 'Passed' } elseif ($env:WARN -eq 'true') { 'Warned' } else { 'Failed' }
Set-Content -LiteralPath (Join-Path $env:DOTNETREPORTS "$env:INSTANCE.txt") -Value "$result ($count executed)"
exit $code
