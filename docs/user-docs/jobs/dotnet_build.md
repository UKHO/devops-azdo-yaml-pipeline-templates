# .NET Build Job

Restores and compiles once, runs optional in-job checks, and publishes packages only after blocking checks pass.

```yaml
jobs:
  - template: jobs/dotnet_build.yml@AzDOPipelineTemplates
    parameters:
      DotNetBuildConfig:                  # Required; SDK defaults to root global.json
        RelativePathToSolution: App.sln
      # CheckoutAlias: AzDOPipelineTemplates # Must match the template resource alias; use self for local templates
      # ArtifactName: DotNetArtifact      # Also the DotNetBuild_<ArtifactName> job suffix
      # DependsOn: []                     # Job dependencies (list)
      # Condition: succeeded()            # Job condition
      # Pool: ''                          # Inherit pool, or supply a pool name
      # PreBuildChecks: []                # After restore (list): DotNetFormat
      # PostBuildChecks: []               # After compile (list): DotNetTest
      # Destinations: []                  # Defaults to PipelineArtifact when Packages is non-empty
```

---

## Output

`Publish` writes `publish/<Name>.zip` (or a directory with `ZipAfterPublish: false`). `NuGet` writes `nuget/<Name>/*.nupkg`. Both go into one pipeline artifact. An empty package list publishes no package artifact. `<ArtifactName>_Reports` contains the summary, resolved SDK and available check evidence, including TRX and coverage when collected.

---

## Examples

### Check and publish a built application

```yaml
jobs:
  - template: jobs/dotnet_build.yml@AzDOPipelineTemplates
    parameters:
      DotNetBuildConfig:
        RelativePathToSolution: App.sln
        Packages:
          - Type: Publish
            Project: src/App/App.csproj
      PreBuildChecks:
        - Check: DotNetFormat
      PostBuildChecks:
        - Check: DotNetTest
          Project: tests/App.Tests/App.Tests.csproj
      Destinations:
        - Type: PipelineArtifact
          Name: BuildOutput
```

**Live example**: [Filtered tests and package verification on Windows or Linux](../../../tests/jobs/dotnet_build/build_test.yml).

## Supported Checks

- [DotNetFormat](../checks/dotnetformat.md) — whitespace before compilation.
- [DotNetTest](../checks/dotnettest.md) — VSTest discovery and outcomes after compilation. All checks run in declaration order within their phase; no `RunAsJob` in the prototype.

## See Also

- [Build configuration](../../definition_docs/dotnet_build/config.md)
- [Build Checks](../checks/README.md)
