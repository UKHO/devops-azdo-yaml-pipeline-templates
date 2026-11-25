$ErrorActionPreference = 'Stop'

dotnet build $env:DOTNETTARGET --no-restore --configuration $env:DOTNETCONFIGURATION
exit $LASTEXITCODE
