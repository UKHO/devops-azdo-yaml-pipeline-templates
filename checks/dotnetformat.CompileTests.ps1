if (!(Get-Command Run-Tests -ErrorAction SilentlyContinue)) {
  . (Join-Path (git rev-parse --show-toplevel) tests/framework/Core.ps1)
}
Run-Tests -YamlPath 'checks/dotnetformat.yml' -ValidTestCases @(
  @{ Description = 'Warning-only named format check'; Parameters = @{ WorkingDirectory = 'src'; Name = 'Format'; TreatAsWarnings = $true }; ExpectedYaml = @('name: PreFormat_Format', 'continueOnError: true', '--verify-no-changes --no-restore') }
)
