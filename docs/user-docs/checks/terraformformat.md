# TerraformFormat Check

Runs `terraform fmt -check -diff` against your Terraform files and fails when any file is not in canonical format. The diff of required changes is written to the step log.

```yaml
Checks:
  - Check: TerraformFormat     # (string, required) Selects this check.
    # Only Check is required - every value below is shown at its default. Uncomment and change a value to override it.

    # Name: ''                 # (string) Unique suffix for the step name. Required, and must be unique, when TerraformFormat is listed more than once.
    # TreatAsWarnings: false   # (boolean) When true, unformatted files produce a warning and the run is "partially succeeded" instead of failing.
    # Recursive: true          # (boolean) When true, also checks files in subdirectories (adds -recursive).
```

The check runs in the build job's Terraform working directory (`RelativePathToTerraformFiles`) using the Terraform version installed by the job.

**Supported by:** [Terraform Build Job](../jobs/terraform_build.md)

To fix a failure locally, run `terraform fmt -recursive` in your Terraform folder and commit the result.

---

## Examples

### Default

Checks the Terraform folder and all subdirectories; any unformatted file fails the build.

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: terraform
      Checks:
        - Check: TerraformFormat
```

**Live example**: [`tests/jobs/terraform_build/checks_terraform_format_test.yml`](../../../tests/jobs/terraform_build/checks_terraform_format_test.yml)

### Top-Level Folder Only

```yaml
Checks:
  - Check: TerraformFormat
    Recursive: false
```

**Live example**: [`tests/jobs/terraform_build/checks_terraform_format_not_recursive_test.yml`](../../../tests/jobs/terraform_build/checks_terraform_format_not_recursive_test.yml)

### Listed Twice With Different Settings

```yaml
Checks:
  - Check: TerraformFormat
    Name: RootOnly
    Recursive: false
  - Check: TerraformFormat
    Name: RootAgain
    Recursive: false
```

Each entry gets its own step (`TerraformTask_fmt_RootOnly` and `TerraformTask_fmt_RootAgain`).

**Live example**: [`tests/jobs/terraform_build/checks_terraform_format_named_twice_test.yml`](../../../tests/jobs/terraform_build/checks_terraform_format_named_twice_test.yml)

### Warn Instead of Fail

```yaml
Checks:
  - Check: TerraformFormat
    TreatAsWarnings: true
```

**Live example**: [`tests/jobs/terraform_build/checks_terraform_format_treat_as_warnings_test.yml`](../../../tests/jobs/terraform_build/checks_terraform_format_treat_as_warnings_test.yml)

---

## See Also

- [Build Checks](./README.md) – How checks work and the common settings
- [Terraform Build Job](../jobs/terraform_build.md) – The job that runs this check
