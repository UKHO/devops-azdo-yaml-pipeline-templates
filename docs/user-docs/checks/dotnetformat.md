# DotNetFormat Check

Verifies whitespace against `.editorconfig` using the restored build target, without changing source or compiling.

```yaml
PreBuildChecks:
  - Check: DotNetFormat
    # Name: ''               # (string) Instance label
    # TreatAsWarnings: false # (boolean) Allow build after a violation
```

**Supported by:** [.NET Build Job](../jobs/dotnet_build.md).

## Examples

**Live example**: [Check format before compile](../../../tests/jobs/dotnet_build/build_test.yml).

## See Also

[Build Checks](README.md)
