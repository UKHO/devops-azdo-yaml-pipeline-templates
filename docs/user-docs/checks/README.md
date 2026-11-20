# Build Checks

Checks are optional quality gates that run inside a build job, after the mandatory validation step and before the artifact is packaged. You enable them by adding entries to the `Checks` parameter of a build job template.

## Available Checks

| Check                                       | Purpose                                                  | Supported By                                      |
| ------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------- |
| **[TerraformFormat](./terraformformat.md)** | Fails when Terraform files are not formatted canonically | [Terraform Build Job](../jobs/terraform_build.md) |

Listing a check that the build job does not support, or misspelling a check or setting name, fails the pipeline at compile time with an error message listing the supported checks.

## Versioning

The check names and their settings are part of this repository's public API and follow [Semantic Versioning](../../developers/reference/versioning-policy.md). Reference checks only through the `Checks` parameter of a build job; do not reference files under `checks/` directly.

---

## Using Checks

The example below uses the [Terraform Build Job](../jobs/terraform_build.md), but checks are not limited to it. Any build job with a `Checks` parameter accepts them in the same way; see the **Supported By** column above for which checks each build job supports.

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      Checks:
        - Check: TerraformFormat
```

Each entry names the check with `Check:` and may add any settings that check supports. Settings you leave out use the check's defaults, so `- Check: <Name>` on its own is always valid.

### Treating Failures as Warnings

Set `TreatAsWarnings: true` to report problems without blocking the build. The step is marked with a warning, the run finishes as **partially succeeded**, and the artifact is still published.

### Running the Same Check More Than Once

You may list a check several times with different settings, as long as each duplicate has a unique, non-empty `Name`:

```yaml
Checks:
  - Check: TerraformFormat
    Name: Root
    Recursive: false
  - Check: TerraformFormat
    Name: All
```

---

## Where Checks Run

Every build job runs in the same order:

1. **Prepare** – the job gets the source and tools ready (for example checkout, custom steps, tool installation and initialisation).
2. **Mandatory** – the job's built-in validation, which always runs.
3. **Checks** – each entry in `Checks`, in the order you list them.
4. **Package** – the artifact is published.

A failing check fails the build, so nothing is packaged or deployed unless you opt into warnings (see [Treating Failures as Warnings](#treating-failures-as-warnings)). See each build job's documentation for exactly what its Prepare and Mandatory phases contain.
