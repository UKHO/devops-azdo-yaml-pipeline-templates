# Terraform Build Job

A specialized job template that builds, validates, and packages Terraform files for deployment.

---

## Basic Usage

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      # No parameters are required - every value below is shown at its default. Uncomment and change a value to override it.

      # RelativePathToTerraformFiles: ''             # Relative path from repo root to your terraform files; empty defaults to repo root.
      # TerraformVersion: '1.14.0'                   # Exact terraform version, or 'latest'; wildcards like '1.5.x' are not allowed.
      # ArtifactName: 'TerraformArtifact'            # Name of the published artifact.
      # Pool: ''                                     # Agent pool to run this job on; empty uses the pipeline/stage default pool.
      # DependsOn: [ ]                               # List of jobs this job depends on.
      # Condition: succeeded()                       # Condition controlling whether this job runs.

      # AdditionalFilesToPackage: [ ]                # Extra files/folders to bundle into the artifact alongside the terraform files. Example item structure:
      #   - SourceDirectory: 'config/shared'         # Relative path from repo root to source directory.
      #     FilesPattern: '*.tfvars'                 # Glob pattern for files to copy.
      #     TargetSubdirectoryName: 'shared-config'  # Subdirectory name inside the artifact.

      # TerraformBuildInjectionSteps: [ ]            # Custom steps run once, before terraform init/validate. Example item structure:
      #   - pwsh: |
      #       Write-Host "Custom preprocessing..."
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
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: terraform
      TerraformVersion: '1.5.0'
```

**Live example**: [`tests/jobs/terraform_build/build_test.yml`](../../../tests/jobs/terraform_build/build_test.yml) (also see [`double_build_test.yml`](../../../tests/jobs/terraform_build/double_build_test.yml) for running two builds in one pipeline)

### Custom Pool Selection

```yaml
jobs:
  - template: jobs/terraform_build.yml
    parameters:
      RelativePathToTerraformFiles: terraform
      TerraformVersion: '1.5.0'
      Pool: 'Linux Self-Hosted'  # Use specific agent pool
```

### With Additional Files

```yaml
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

**Live example**: [`tests/jobs/terraform_build/additional_files_test.yml`](../../../tests/jobs/terraform_build/additional_files_test.yml)

### With Custom Injection Step

```yaml
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

**Live example**: [`tests/jobs/terraform_build/injection_steps_test.yml`](../../../tests/jobs/terraform_build/injection_steps_test.yml)

---

## See Also

- [Terraform Deploy Job](./terraform_deploy.md) – Uses artifact from this job
- [Terraform Gated Deployment Job](./terraform_gated_deployment.md) – Orchestrates build with deploy
- [Terraform Pipeline](../pipelines/terraform_pipeline.md) – Complete pipeline using this job
- [Additional Files Packaging Guide](../pipelines/terraform_pipeline_additional_files_to_package.md) – Detailed guide on file patterns
