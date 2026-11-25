$ErrorActionPreference = 'Stop'

dotnet format whitespace $env:DOTNETTARGET --verify-no-changes --no-restore
$code = $LASTEXITCODE
$result = if (!$code) { 'Passed' } elseif ($env:WARN -eq 'true') { 'Warned' } else { 'Failed' }
Set-Content -LiteralPath (Join-Path $env:DOTNETREPORTS "$env:INSTANCE.txt") -Value $result
exit $code
