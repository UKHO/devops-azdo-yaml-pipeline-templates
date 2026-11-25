$ErrorActionPreference = 'Stop'

$options = @("-p:Configuration=$env:DOTNETCONFIGURATION")
$restore = if ($env:RESTORE_JSON) { ConvertFrom-Json $env:RESTORE_JSON }
if ($restore.UseLockedMode -eq $true) { $options += '--locked-mode' }
if ($restore.NuGetConfigPath) { $options += '--configfile', $restore.NuGetConfigPath }
dotnet restore $env:DOTNETTARGET @options
exit $LASTEXITCODE
