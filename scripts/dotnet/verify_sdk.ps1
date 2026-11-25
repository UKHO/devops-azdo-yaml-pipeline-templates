$ErrorActionPreference = 'Stop'

$sdk = dotnet --version
if ($LASTEXITCODE) { throw 'The requested SDK is not available.' }
if ($env:EXPECTED -and $sdk -ne $env:EXPECTED) { throw "Expected SDK $env:EXPECTED, resolved $sdk" }
Set-Content -LiteralPath (Join-Path $env:DOTNETREPORTS sdk.txt) -Value $sdk
