if (!(Get-Command Run-Tests -ErrorAction SilentlyContinue)) {
  . (Join-Path (git rev-parse --show-toplevel) tests/framework/Core.ps1)
}
Run-Tests -YamlPath 'checks/dotnetcoretest.yml' -ValidTestCases @(
  @{ Description = 'Named filtered test'; Parameters = @{ WorkingDirectory = 'src'; Name = 'Unit'; Filter = 'TestCategory=Unit' }; ExpectedYaml = @('name: PostTest_Unit', 'command: test', 'TestCategory=Unit', 'publishTestResults: false', 'validate_test_evidence.ps1', 'PublishTestResults@2') }
) -InvalidTestCases @(
  @{ Description = 'Reject missing working directory'; Parameters = @{}; ErrorMessage = 'WorkingDirectory' }
)
