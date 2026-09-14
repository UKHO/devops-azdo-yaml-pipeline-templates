# Terraform Build Job

A specialized job template that builds, validates, and packages Terraform files for deployment.

---

## Basic Usage

```yaml
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml
        parameters:
          # No parameters are strictly required - every parameter below has a default. Uncomment and set the ones you need.

          # RelativePathToTerraformFiles: infra/terraform # Optional. Relative path from repo root to your terraform files. Default '' (repo root).
          # TerraformVersion: '1.5.0' # Optional. Exact terraform version (default '1.14.0') or 'latest'; wildcards like '1.5.x' are not allowed.
          # ArtifactName: TerraformArtifact # Optional. Name of the published artifact; override if running multiple builds in one pipeline.
          # AdditionalFilesToPackage: # Optional. Extra files/folders to bundle into the artifact alongside the terraform files.
          #   - SourceDirectory: 'config/shared' # Required (per item). Relative path from repo root to source directory.
          #     FilesPattern: '*.tfvars' # Required (per item). Glob pattern for files to copy.
          #     TargetSubdirectoryName: 'shared-config' # Required (per item). Subdirectory name inside the artifact.

          # TerraformBuildInjectionSteps: # Optional. Custom steps to run once, before terraform init/validate (e.g. inject required_version).
          #   - pwsh: |
          #       Write-Host "Custom preprocessing..."

          # Pool: 'Linux Self-Hosted' # Optional. Agent pool to run this job on; empty uses the pipeline/stage default pool.
          # DependsOn: # Optional. List of jobs this job depends on. Default [ ] (no dependencies).
          #   - SomeOtherJobName
          # Condition: succeeded() # Optional. Condition controlling whether this job runs. Default succeeded().
```

---

## Artifact Output

```
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
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml
        parameters:
          RelativePathToTerraformFiles: terraform
          TerraformVersion: '1.5.0'
```

### Custom Pool Selection

```yaml
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml
        parameters:
          RelativePathToTerraformFiles: terraform
          TerraformVersion: '1.5.0'
          Pool: 'Linux Self-Hosted'  # Use specific agent pool
```

### With Additional Files

```yaml
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml
        parameters:
          RelativePathToTerraformFiles: infra/terraform
          TerraformVersion: '1.5.0'
          AdditionalFilesToPackage:
            - SourceDirectory: 'config'
              FilesPattern: '**/*.tfvars'
              TargetSubdirectoryName: 'configs'
            - SourceDirectory: 'scripts/deploy'
              FilesPattern: '**/*.sh'
              TargetSubdirectoryName: 'deploy-scripts'
```

### With Custom Injection Step

```yaml
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml
        parameters:
          RelativePathToTerraformFiles: infra/webapp
          TerraformVersion: '1.5.0'
          TerraformBuildInjectionSteps:
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

---

## Live Examples

View working test examples in the repository:

- **Basic Build**: [`tests/jobs/terraform_build/build_test.yml`](../../../tests/jobs/terraform_build/build_test.yml)
- **Double Build**: [`tests/jobs/terraform_build/double_build_test.yml`](../../../tests/jobs/terraform_build/double_build_test.yml)
- **With Injection Steps**: [`tests/jobs/terraform_build/injection_steps_test.yml`](../../../tests/jobs/terraform_build/injection_steps_test.yml)
- **With Additional Files**: [`tests/jobs/terraform_build/additional_files_test.yml`](../../../tests/jobs/terraform_build/additional_files_test.yml)

## See Also

- [Terraform Deploy Job](./terraform_deploy.md) – Uses artifact from this job
- [Terraform Gated Deployment Job](./terraform_gated_deployment.md) – Orchestrates build with deploy
- [Terraform Pipeline](../pipelines/terraform_pipeline.md) – Complete pipeline using this job
- [Additional Files Packaging Guide](../pipelines/terraform_pipeline_additional_files_to_package.md) – Detailed guide on file patterns
