# UkhoSnykIacScan Check

Scans your Terraform for security misconfigurations with Snyk (`snyk iac test`) via the **UKHO Snyk scan task** (`UkhoSnykScanTask`) and fails the build when it finds issues at or above the severity threshold. A JSON report of the scan is attached to the pipeline run.

```yaml
Checks:
  - Check: UkhoSnykIacScan        # (string, required) Selects this check.
    ServiceConnection: Snyk       # (string, required) Name of your Snyk Authentication service connection.
    Organization: my-team         # (string, required) Snyk organisation slug or ID.
    # Only the settings above are required - every value below is shown at its default. Uncomment and change a value to override it.

    # Name: ''                    # (string) Unique suffix for the step and report names. Required, and must be unique, when UkhoSnykIacScan is listed more than once.
    # TreatAsWarnings: false      # (boolean) When true, issues or scan errors produce a warning and the run is "partially succeeded" instead of failing.
    # SeverityThreshold: low      # (string) Lowest severity that fails the check: low, medium, high or critical.
    # AdditionalArguments: ''     # (string) Extra Snyk CLI arguments, passed through as-is (for example '--report'). Not covered by versioning.
    # Debug: false                # (boolean) When true, turns on Snyk CLI debug logging (-d) in the step log.
```

The check scans the build job's Terraform working directory (`RelativePathToTerraformFiles`) and everything below it.

**Supported by:** [Terraform Build Job](../jobs/terraform_build.md)

---

## Prerequisites

- The [**UKHO Azure Pipeline Scan Task**](https://github.com/UKHO/ukho-azure-pipeline-scan-task) extension (`ukho-azure-pipeline-scan-task`) installed in your Azure DevOps organisation. It provides the `UkhoSnykScanTask` task.
- A Snyk **Enterprise** plan. The check authenticates with a Snyk service account, and [Snyk only offers service accounts on Enterprise plans](https://docs.snyk.io/platform-administration/service-accounts/service-accounts).
- A Snyk service account for your team's Snyk organisation, and a **Snyk Authentication** service connection in your Azure DevOps project that uses it. The service connection must be authorised for the pipeline.
- Agents with outbound internet access to `downloads.snyk.io` and the Snyk API. The task downloads the Snyk CLI on every run and does not support proxies.

---

## Behaviour

- **What fails the build:** any issue at or above `SeverityThreshold`, and any scan error such as an invalid token or no Terraform files found. To report these as a warning instead, set `TreatAsWarnings: true`; there is no setting that hides them.
- **External modules are only partly covered:** the check runs after `terraform init`, so the `.tf` files of modules downloaded into `.terraform/` are scanned as files. However, [Snyk's static Terraform scan does not support external modules](https://docs.snyk.io/developer-tools/snyk-cli/scan-and-maintain-projects-using-the-cli/snyk-cli-for-iac/test-your-iac-files/terraform-files), so it does not check how you call a module or the input values you pass to it. To cover the resources your modules actually create, also scan a Terraform plan (`snyk iac test` on a `terraform show -json` plan file); built-in support for this in the deploy jobs is tracked in [#109](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/issues/109).
- **Reports:** a JSON report named `snyk-iac` (or `snyk-iac-<Name>`) is attached to the run. It is not added to the Terraform artifact. The task currently also attaches an HTML report and shows the results on a scan report tab. All reports come from the task and are not covered by versioning.
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
        - Check: UkhoSnykIacScan
          ServiceConnection: Snyk
          Organization: my-team
```

**Live example**: [`tests/jobs/terraform_build/checks_ukho_snyk_iac_scan_clean_test.yml`](../../../tests/jobs/terraform_build/checks_ukho_snyk_iac_scan_clean_test.yml), and [`tests/jobs/terraform_build/checks_ukho_snyk_iac_scan_report_attached_test.yml`](../../../tests/jobs/terraform_build/checks_ukho_snyk_iac_scan_report_attached_test.yml) for the attached JSON report

### Only Fail on High and Critical Issues

```yaml
Checks:
  - Check: UkhoSnykIacScan
    ServiceConnection: Snyk
    Organization: my-team
    SeverityThreshold: high
```

### Warn Instead of Fail

```yaml
Checks:
  - Check: UkhoSnykIacScan
    ServiceConnection: Snyk
    Organization: my-team
    TreatAsWarnings: true
```

**Live example**: [`tests/jobs/terraform_build/checks_ukho_snyk_iac_scan_treat_as_warnings_test.yml`](../../../tests/jobs/terraform_build/checks_ukho_snyk_iac_scan_treat_as_warnings_test.yml)

### Upload Results to Snyk

```yaml
Checks:
  - Check: UkhoSnykIacScan
    ServiceConnection: Snyk
    Organization: my-team
    AdditionalArguments: --report --target-name=my-infrastructure
```

---

## See Also

- [Build Checks](./README.md) – How checks work and the common settings
- [Terraform Build Job](../jobs/terraform_build.md) – The job that runs this check
- [Snyk CLI `iac test`](https://docs.snyk.io/snyk-cli/commands/iac-test) – Options you can pass in `AdditionalArguments`
