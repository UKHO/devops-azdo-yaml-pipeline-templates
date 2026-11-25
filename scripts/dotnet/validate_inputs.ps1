$ErrorActionPreference = 'Stop'

$null = New-Item -ItemType Directory -Force $env:DOTNETREPORTS
$config = ConvertFrom-Json $env:CONFIG_JSON
function Assert-SourceFile($path) {
  if (!$path -or [IO.Path]::IsPathRooted($path) -or $path -match '(^|[\\/])\.\.([\\/]|$)' -or !(Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Expected an existing repository-relative file: '$path'"
  }
}
Assert-SourceFile $config.RelativePathToSolution
if ($config.Restore.NuGetConfigPath) { Assert-SourceFile $config.Restore.NuGetConfigPath }
foreach ($phase in 'PRE_JSON','POST_JSON') {
  foreach ($entry in (ConvertFrom-Json ([Environment]::GetEnvironmentVariable($phase)))) {
    if ($entry.Name -and $entry.Name -notmatch '^[A-Za-z0-9_]+$') { throw 'Invalid check Name' }
    if ($entry.Project) { Assert-SourceFile $entry.Project }
  }
}
$names = @{}
foreach ($package in $config.Packages) {
  Assert-SourceFile $package.Project
  $name = if ($package.Name) { $package.Name } else { [IO.Path]::GetFileNameWithoutExtension($package.Project) }
  if ($name -notmatch '^[A-Za-z0-9_][A-Za-z0-9_.-]*$' -or $name.EndsWith('.') -or $names.ContainsKey($name)) { throw "Invalid or duplicate package name: $name" }
  $names[$name] = $true
}
if (!$config.DotNetSdk.Version -and !(Test-Path -LiteralPath global.json)) { throw 'Provide DotNetSdk.Version or a global.json at the repository root.' }
