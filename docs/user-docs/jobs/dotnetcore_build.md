# .NET Core Build Job

Restores and compiles once, runs optional in-job checks, and publishes packages only after blocking checks pass.

```yaml
jobs:
  - template: jobs/dotnetcore_build.yml@AzDOPipelineTemplates
    parameters:
      DotNetCoreBuildConfig:                  # Required; SDK defaults to root global.json
        RelativePathToSolution: App.sln
      # CheckoutAlias: AzDOPipelineTemplates # Must match the template resource alias; use self for local templates
      # ArtifactName: DotNetCoreArtifact      # Also the DotNetCoreBuild_<ArtifactName> job suffix
      # DependsOn: []                     # Job dependencies (list)
      # Condition: succeeded()            # Job condition
      # Pool: ''                          # Inherit pool, or supply a pool name
      # PreBuildChecks: []                # After restore (list): DotNetCoreFormat
      # PostBuildChecks: []               # After compile (list): DotNetCoreTest
      # Destinations: []                  # Defaults to PipelineArtifact when Packages is non-empty
```

---

SDK installation uses `UseDotNet@2`. `DotNetCoreCLI@2` runs the build commands; restore honours normal NuGet config discovery unless `Restore.NuGetConfigPath` is supplied. Tests publish TRX separately so the task does not relocate results. The summary reads native task verdicts from the current job timeline; unavailable verdicts are not counted as passes.

## Output

`Publish` writes `publish/<Name>.zip` (or a directory with `ZipAfterPublish: false`). `NuGet` writes `nuget/<Name>/*.nupkg`. Both go into one pipeline artifact. An empty package list publishes no package artifact. `<ArtifactName>_Reports` contains the summary, resolved SDK and available check evidence, including TRX and coverage when collected.

---

## Examples

### Check and publish a built application

```yaml
jobs:
  - template: jobs/dotnetcore_build.yml@AzDOPipelineTemplates
    parameters:
      DotNetCoreBuildConfig:
        RelativePathToSolution: App.sln
        Packages:
          - Type: Publish
            Project: src/App/App.csproj
      PreBuildChecks:
        - Check: DotNetCoreFormat
      PostBuildChecks:
        - Check: DotNetCoreTest
          Project: tests/App.Tests/App.Tests.csproj
      Destinations:
        - Type: PipelineArtifact
          Name: BuildOutput
```

**Live example**: [Filtered tests and package verification on Windows or Linux](../../../tests/jobs/dotnetcore_build/build_test.yml).

## Supported Checks

- [DotNetCoreFormat](../checks/dotnetcoreformat.md) — whitespace before compilation.
- [DotNetCoreTest](../checks/dotnetcoretest.md) — VSTest discovery and outcomes after compilation. All checks run in declaration order within their phase; no `RunAsJob` in the prototype.

## See Also

- [Build configuration](../../definition_docs/dotnetcore_build/config.md)
- [Build Checks](../checks/README.md)
