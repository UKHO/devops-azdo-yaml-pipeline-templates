# The config has already passed validate_inputs.ps1. Template expressions cannot take a path's basename.
$ErrorActionPreference = 'Stop'
$name = [IO.Path]::GetFileNameWithoutExtension($env:PACKAGE_PROJECT)
if ($name -notmatch '^[A-Za-z0-9_][A-Za-z0-9_.-]*$') { throw 'Invalid default package name' }
Write-Host "##vso[task.setvariable variable=DotNetCoreDefaultPackageName]$name"
