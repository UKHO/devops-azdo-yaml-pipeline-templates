# Terraform Build Job

A specialized job template that builds, validates, and packages Terraform files for deployment.

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      # No parameters are required - every value below is shown at its default. Uncomment and change a value to override it.

      # Pool: ''                                       # (string) Agent pool to run this job on; empty uses the pipeline/stage default pool.
      # DependsOn:                                     # (list) Jobs this job depends on. Defaults to an empty list.
      # Condition: succeeded()                         # (string) Condition controlling whether this job runs.

      # TerraformBuildConfig:                          # (object) What to build. Defaults to an empty object.
      #   ArtifactName: 'TerraformArtifact'            # (string) Name of the published artifact; also names the job (TerraformBuild_<ArtifactName>).
      #   TerraformVersion: '1.14.0'                   # (string) Exact terraform version, or 'latest'; wildcards like '1.5.x' are not allowed.
      #   RelativePathToTerraformFiles: ''             # (string) Relative path from repo root to your terraform files; empty defaults to repo root.

      #   AdditionalFilesToPackage:                    # (list) Extra files/folders to bundle into the artifact alongside the terraform files. Defaults to an empty list. Example item structure:
      #     - SourceDirectory: 'config/shared'         # (string, required) Relative path from repo root to source directory.
      #       FilesPattern: '*.tfvars'                 # (string, required) Glob pattern for files to copy.
      #       TargetSubdirectoryName: 'shared-config'  # (string) Subdirectory name inside the artifact; empty copies to the artifact root.

      #   InjectionSteps:                              # (list) Custom steps run once, before terraform init/validate. Defaults to an empty list. Example item structure:
      #     - pwsh: |
      #         Write-Host "Custom preprocessing..."

      #   Checks:                                      # (list) Quality checks run after terraform validate, before packaging. Defaults to an empty list. Each check has its own settings - see Supported Checks below. Example:
      #     - Check: TerraformFormat
      #     - Check: SnykIac
```

A misspelled or unknown `TerraformBuildConfig` field fails the pipeline when it compiles, with a message listing the supported fields.

---

## Supported Checks

`TerraformBuildConfig.Checks` accepts the following checks. See [Build Checks](../checks/README.md) for how checks run and the settings every check shares.

- [TerraformFormat](../checks/terraformformat.md) – Fails when Terraform files are not formatted canonically (`terraform fmt -check`).
- [SnykIac](../checks/snykiac.md) – Scans Terraform for security misconfigurations with Snyk (needs the UKHO Snyk extension and a Snyk service connection).

---

## Deprecated Parameters

Before `TerraformBuildConfig`, the build settings were top-level parameters. They still work until the next major release, but each one used logs a warning on the run (in a `DeprecatedParametersWarning` step), and setting a field both ways fails the compile. Checks are only available in `TerraformBuildConfig`.

- `ArtifactName` → `TerraformBuildConfig.ArtifactName`
- `TerraformVersion` → `TerraformBuildConfig.TerraformVersion`
- `RelativePathToTerraformFiles` → `TerraformBuildConfig.RelativePathToTerraformFiles`
- `AdditionalFilesToPackage` → `TerraformBuildConfig.AdditionalFilesToPackage`
- `TerraformBuildInjectionSteps` → `TerraformBuildConfig.InjectionSteps`

See the [upgrade guide](../upgrades/0.4.x-to-0.5.0-terraform-build-config.md) for how to move across.

---

## Artifact Output

```text
TerraformArtifact/
├── main.tf                    # From RelativePathToTerraformFiles
├── variables.tf
├── outputs.tf
├── shared-config/             # From AdditionalFilesToPackage
│   ├── common.tfvars
│   └── shared.tfvars
└── deploy-scripts/
    ├── deploy.sh
    └── validate.sh
```

---

## Examples

### Basic Terraform Build

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      TerraformBuildConfig:
        RelativePathToTerraformFiles: terraform
        TerraformVersion: '1.5.0'
```

**Live example**: [`tests/jobs/terraform_build/build_test.yml`](../../../tests/jobs/terraform_build/build_test.yml) (also see [`double_build_test.yml`](../../../tests/jobs/terraform_build/double_build_test.yml) for running two builds in one pipeline)

### Custom Pool Selection

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      Pool: 'Linux Self-Hosted'  # Use specific agent pool
      TerraformBuildConfig:
        RelativePathToTerraformFiles: terraform
```

### With Additional Files

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      TerraformBuildConfig:
        RelativePathToTerraformFiles: infra/terraform
        AdditionalFilesToPackage:
          - SourceDirectory: 'config'
            FilesPattern: '**/*.tfvars'
            TargetSubdirectoryName: 'configs'
          - SourceDirectory: 'scripts/deploy'
            FilesPattern: '**/*.sh'
            TargetSubdirectoryName: 'deploy-scripts'
```

**Live example**: [`tests/jobs/terraform_build/additional_files_test.yml`](../../../tests/jobs/terraform_build/additional_files_test.yml)

### With Custom Injection Step

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      TerraformBuildConfig:
        RelativePathToTerraformFiles: infra/webapp
        InjectionSteps:
          - pwsh: |
              $tfDir = "$(Pipeline.Workspace)/$(Build.Repository.Name)/infra/webapp"
              $mainTf = "$tfDir/main.tf"
              $content = Get-Content $mainTf -Raw

              if ($content -match 'terraform\s*\{') {
                $content = $content -replace '(terraform\s*\{)', "`$1`n  required_version = `"1.5.0`""
                Set-Content $mainTf $content
              }
            displayName: 'Inject required_version constraint'
```

**Live example**: [`tests/jobs/terraform_build/injection_steps_test.yml`](../../../tests/jobs/terraform_build/injection_steps_test.yml)

### With Checks

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      TerraformBuildConfig:
        RelativePathToTerraformFiles: terraform
        Checks:
          - Check: TerraformFormat
```

**Live example**: [`tests/jobs/terraform_build/checks_terraform_format_test.yml`](../../../tests/jobs/terraform_build/checks_terraform_format_test.yml) – more examples in the [TerraformFormat check docs](../checks/terraformformat.md#examples)

### Deprecated Parameters (Still Supported)

**Live example**: [`tests/jobs/terraform_build/deprecated_parameters_test.yml`](../../../tests/jobs/terraform_build/deprecated_parameters_test.yml) – every deprecated parameter, proving they still work and log a warning.

---

## See Also

- [Build Checks](../checks/README.md) – Optional quality checks for this job
- [Upgrade guide: TerraformBuildConfig](../upgrades/0.4.x-to-0.5.0-terraform-build-config.md) – Moving from the deprecated parameters
- [Terraform Deploy Job](./terraform_deploy.md) – Uses artifact from this job
- [Terraform Gated Deployment Job](./terraform_gated_deployment.md) – Orchestrates build with deploy
- [Terraform Pipeline](../pipelines/terraform_pipeline.md) – Complete pipeline using this job
- [Additional Files Packaging Guide](../pipelines/terraform_pipeline_additional_files_to_package.md) – Detailed guide on file patterns
