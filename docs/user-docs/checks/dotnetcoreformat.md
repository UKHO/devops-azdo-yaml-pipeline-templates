# DotNetCoreFormat Check

Verifies whitespace against `.editorconfig` using the restored build target, without changing source or compiling.

```yaml
PreBuildChecks:
  - Check: DotNetCoreFormat
    # Name: ''               # (string) Instance label
    # TreatAsWarnings: false # (boolean) Allow build after a violation
```

**Supported by:** [.NET Core Build Job](../jobs/dotnetcore_build.md).

## Examples

**Live example**: [Check format before compile](../../../tests/jobs/dotnetcore_build/build_test.yml).

## See Also

[Build Checks](README.md)
