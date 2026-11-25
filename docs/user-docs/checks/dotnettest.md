# DotNetTest Check

Runs previously compiled VSTest projects. A failed command or zero executed tests fails the check.

```yaml
PostBuildChecks:
  - Check: DotNetTest
    # Name: ''               # (string) Required on repeated instances
    # TreatAsWarnings: false # (boolean) Warn rather than block packaging
    # Project: ''            # (string) Built project or solution; defaults to build target
    # Filter: ''             # (string) VSTest filter expression
    # TestRunTitle: ''       # (string) Defaults to instance name or target
    # CollectCoverage: true  # (boolean) Requires a compatible XPlat collector in the test project
```

**Supported by:** [.NET Build Job](../jobs/dotnet_build.md). Use projects included in the mandatory build. Missing coverage is reported as unavailable, not zero. Coverage thresholds and separate check jobs are not supported.

## Examples

**Live example**: [Two named NUnit filters with isolated TRX results](../../../tests/jobs/dotnet_build/build_test.yml).

## See Also

[Build Checks](README.md)
