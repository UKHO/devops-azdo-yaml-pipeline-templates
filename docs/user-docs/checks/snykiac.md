# SnykIac Check

Scans your Terraform for security misconfigurations with Snyk (`snyk iac test`) and fails the build when it finds issues at or above the severity threshold. The scan reports are attached to the pipeline run.

```yaml
Checks:
  - Check: SnykIac                  # (string, required) Selects this check.
    ServiceConnection: Snyk         # (string, required) Name of your Snyk Authentication service connection.
    Organization: my-team           # (string, required) Snyk organisation slug or ID.
    # Only the settings above are required - every value below is shown at its default. Uncomment and change a value to override it.

    # Name: ''                      # (string) Unique suffix for the step and report names. Required, and must be unique, when SnykIac is listed more than once.
    # TreatAsWarnings: false        # (boolean) When true, issues or scan errors produce a warning and the run is "partially succeeded" instead of failing.
    # SeverityThreshold: low        # (string) Lowest severity that fails the check: low, medium, high or critical.
    # FailOnIssues: true            # (boolean) When false, the check always succeeds - including when the scan itself fails. Prefer TreatAsWarnings.
    # AdditionalArguments: ''       # (string) Extra Snyk CLI arguments, passed through as-is (for example '--report'). Not covered by versioning.
```

The check scans the build job's Terraform working directory (`RelativePathToTerraformFiles`) and everything below it.

**Supported by:** [Terraform Build Job](../jobs/terraform_build.md)

---

## Prerequisites

- The **UKHO Azure Pipeline Scan Task** extension installed in your Azure DevOps organisation.
- A Snyk service account for your team's Snyk organisation, and a **Snyk Authentication** service connection in your Azure DevOps project that uses it. The service connection must be authorised for the pipeline.
- Agents with outbound internet access to `downloads.snyk.io` and the Snyk API. The task downloads the Snyk CLI on every run and does not support proxies.

---

## Behaviour

- **What fails the build:** any issue at or above `SeverityThreshold`, and any scan error such as an invalid token or no Terraform files found.
- **`TreatAsWarnings` vs `FailOnIssues`:** `TreatAsWarnings: true` still shows issues and scan errors as a warning. `FailOnIssues: false` makes the step succeed whatever happens, so a broken scan looks the same as a clean one. Use `TreatAsWarnings` unless you have a reason not to.
- **Downloaded modules are scanned:** the check runs after `terraform init`, so module source downloaded into `.terraform/` is scanned along with your own files.
- **Reports:** JSON and HTML reports named `snyk-iac` (or `snyk-iac-<Name>`) are attached to the run and shown on the scan report tab. They are not added to the Terraform artifact.
- **Results in Snyk:** results are not uploaded to Snyk unless you add `--report` to `AdditionalArguments`.

---

## Examples

### Default

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: terraform
      Checks:
        - Check: SnykIac
          ServiceConnection: Snyk
          Organization: my-team
```

### Only Fail on High and Critical Issues

```yaml
Checks:
  - Check: SnykIac
    ServiceConnection: Snyk
    Organization: my-team
    SeverityThreshold: high
```

### Warn Instead of Fail

```yaml
Checks:
  - Check: SnykIac
    ServiceConnection: Snyk
    Organization: my-team
    TreatAsWarnings: true
```

### Upload Results to Snyk

```yaml
Checks:
  - Check: SnykIac
    ServiceConnection: Snyk
    Organization: my-team
    AdditionalArguments: --report --project-name=my-infrastructure
```

---

## See Also

- [Build Checks](./README.md) – How checks work and the common settings
- [Terraform Build Job](../jobs/terraform_build.md) – The job that runs this check
- [Snyk CLI `iac test`](https://docs.snyk.io/snyk-cli/commands/iac-test) – Options you can pass in `AdditionalArguments`
