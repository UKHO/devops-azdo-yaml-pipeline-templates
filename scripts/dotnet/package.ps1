$ErrorActionPreference = 'Stop'

foreach ($package in (ConvertFrom-Json $env:PACKAGES_JSON)) {
  $name = if ($package.Name) { $package.Name } else { [IO.Path]::GetFileNameWithoutExtension($package.Project) }
  $argsList = @($package.Project, '--no-build', '--no-restore', '-c', $env:DOTNETCONFIGURATION)
  if ($package.Type -eq 'NuGet') {
    dotnet pack @argsList -o (Join-Path $env:DOTNETPACKAGES nuget $name)
  } else {
    $out = Join-Path $env:DOTNETPACKAGES publish $name
    dotnet publish @argsList -o $out
    if (!$LASTEXITCODE -and $package.ZipAfterPublish -ne $false) {
      [IO.Compression.ZipFile]::CreateFromDirectory($out, "$out.zip")
      Remove-Item -Recurse -LiteralPath $out
    }
  }
  if ($LASTEXITCODE) { exit $LASTEXITCODE }
}
