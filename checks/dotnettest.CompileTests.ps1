if (!(Get-Command Run-Tests -ErrorAction SilentlyContinue)) {
  . (Join-Path (git rev-parse --show-toplevel) tests/framework/Core.ps1)
}
Run-Tests -YamlPath 'checks/dotnettest.yml' -ValidTestCases @(
  @{ Description = 'Named filtered test'; Parameters = @{ WorkingDirectory = 'src'; Name = 'Unit'; Filter = 'TestCategory=Unit' }; ExpectedYaml = @('name: PostTest_Unit', 'TEST_FILTER: TestCategory=Unit', 'PublishTestResults@2') }
) -InvalidTestCases @(
  @{ Description = 'Reject missing working directory'; Parameters = @{}; ErrorMessage = 'WorkingDirectory' }
)
