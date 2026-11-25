if (!(Get-Command Run-Tests -ErrorAction SilentlyContinue)) {
  . (Join-Path (git rev-parse --show-toplevel) tests/framework/Core.ps1)
}
$config = 'RelativePathToSolution: Sample.sln'
Run-Tests -YamlPath 'jobs/dotnet_build.yml' -ValidTestCases @(
  @{ Description = 'Build without packages'; Parameters = @{ DotNetBuildConfig = $config }; ExpectedYaml = @('job: DotNetBuild_DotNetArtifact', 'Build once') }
  @{ Description = 'Local template checkout and file-based job wiring'; Parameters = @{ DotNetBuildConfig = $config; CheckoutAlias = 'self' }; ExpectedYaml = @('$(DotNetSource)/scripts/dotnet', 'filePath: $(DotNetScriptRoot)/validate_inputs.ps1', 'filePath: $(DotNetScriptRoot)/build.ps1') }
  @{ Description = 'Compile ordered pre and post checks'; Parameters = @{ DotNetBuildConfig = $config; PreBuildChecks = '- Check: DotNetFormat'; PostBuildChecks = '- Check: DotNetTest' }; ExpectedYaml = @('PreFormat_*Build once*PostTest_') }
) -InvalidTestCases @(
  @{ Description = 'Reject wrong phase'; Parameters = @{ DotNetBuildConfig = $config; PreBuildChecks = '- Check: DotNetTest' }; ErrorMessage = 'Invalid check phase' }
  @{ Description = 'Reject deferred destination'; Parameters = @{ DotNetBuildConfig = $config; Destinations = '- Type: NuGetFeed' }; ErrorMessage = 'Only PipelineArtifact is supported' }
  @{ Description = 'Reject independent job option'; Parameters = @{ DotNetBuildConfig = $config; PostBuildChecks = "- Check: DotNetTest`n  RunAsJob: {}" }; ErrorMessage = "Unexpected parameter 'RunAsJob'" }
)
