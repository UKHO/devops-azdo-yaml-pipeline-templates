# Terraform Build Job

A specialized job template that builds, validates, and packages Terraform files for deployment. This job handles the initial phase of infrastructure-as-code workflows by preparing artifacts for deployment stages.

---

## When to Use

Use this job template when you need to:

- **Validate Terraform configuration** – Check syntax and structure
- **Package infrastructure code** – Create deployable artifacts
- **Run pre-deployment steps** – Execute custom validation or transformation logic
- **Support infrastructure workflows** – Single standardized build for all Terraform deployments

This job is the foundation of the Terraform Pipeline and is used in the Build stage automatically.

---

## What This Job Does

1. **Checks out** your repository containing Terraform files
2. **Executes injection steps** (if provided) for custom preprocessing
3. **Packages additional files** (if specified) alongside Terraform files
4. **Installs Terraform CLI** of the specified version
5. **Runs `terraform init`** without backend configuration for validation
6. **Runs `terraform validate`** to check configuration syntax
7. **Cleans up** temporary files (`.terraform` directory)
8. **Publishes artifact** containing all packaged files for deployment stages

---

## Basic Usage

```yaml
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml
        parameters:
          RelativePathToTerraformFiles: infra/terraform
          TerraformVersion: '1.5.0'
```

---

## Parameters

### Required Parameters

| Parameter                      | Type   | Description                                                                                                                                       |
|--------------------------------|--------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| `RelativePathToTerraformFiles` | string | Relative path from repository root to terraform files (e.g., `infra/`, `terraform/`). Path is relative to repo root, not workspace.               |
| `TerraformVersion`             | string | Terraform CLI version to install. Use `'latest'` for latest version or semantic version like `'1.5.0'`. Wildcards like `'1.5.x'` are not allowed. |

### Optional Parameters

| Parameter                      | Type     | Default             | Description                                                 |
|--------------------------------|----------|---------------------|-------------------------------------------------------------|
| `ArtifactName`                 | string   | `TerraformArtifact` | Name of the published artifact for later retrieval          |
| `Pool`                         | string   | `''`                | Agent pool to run job on. Empty uses default pool.          |
| `AdditionalFilesToPackage`     | object   | `[ ]`               | List of additional files to include in artifact (see below) |
| `TerraformBuildInjectionSteps` | stepList | `[ ]`               | Custom steps to run before terraform validation             |

---

## Advanced Parameters

### AdditionalFilesToPackage

Include additional files beyond those in `RelativePathToTerraformFiles`:

Each item is an object with:
- `SourceDirectory` (string, required) – Relative path from repo root to source directory
- `FilesPattern` (string, required) – Glob pattern for files to copy (e.g., `**/*.tfvars`)
- `TargetSubdirectoryName` (string, required) – Subdirectory in artifact for files

```yaml
AdditionalFilesToPackage:
  - SourceDirectory: 'config/shared'
    FilesPattern: '*.tfvars'
    TargetSubdirectoryName: 'shared-config'
  - SourceDirectory: 'scripts'
    FilesPattern: '**/*.ps1'
    TargetSubdirectoryName: 'scripts'
```

### TerraformBuildInjectionSteps

Execute custom steps before terraform validation. These steps run **twice** to ensure modifications are both validated and packaged:

```yaml
TerraformBuildInjectionSteps:
  - task: PowerShell@2
    displayName: 'Generate configuration'
    inputs:
      targetType: 'inline'
      script: |
        Write-Host "Custom preprocessing..."
        # Your custom logic here

  - task: AzureCLI@2
    displayName: 'Retrieve secrets'
    inputs:
      azureSubscription: 'MyServiceConnection'
      scriptType: 'bash'
      scriptLocation: 'inlineScript'
      inlineScript: |
        az keyvault secret show --vault-name myvault --name mysecret
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

This will:
1. Install Terraform 1.5.0
2. Validate terraform files in `$(Pipeline.Workspace)/$(Build.Repository.Name)/terraform/`
3. Create `TerraformArtifact` with packaged files

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

Add a `required_version` constraint to your Terraform block:

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

---

## Artifact Output

The job publishes an artifact containing:

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

Deploy stages download this artifact and use it for planning and applying infrastructure changes.

---

## Troubleshooting

### Build Fails with Terraform Version Error

**Check**:
- ✓ Verify `TerraformVersion` format is correct (e.g., `'1.5.0'`, not `'1.5.x'`)
- ✓ Ensure version exists on [Terraform releases](https://releases.hashicorp.com/terraform/)
- ✓ Check agent has internet access to download Terraform CLI

### Validation Fails

**Check**:
- ✓ Verify Terraform files have correct syntax
- ✓ Check all required providers and modules are available
- ✓ Ensure variable definitions match the Terraform configuration

**Solution**: Review the error message in build logs and fix the Terraform configuration.

### Additional Files Not Included in Artifact

**Check**:
- ✓ Verify `FilesPattern` matches your files (use glob patterns correctly)
- ✓ Ensure `SourceDirectory` exists and is relative to repo root
- ✓ Check case sensitivity (Linux agents are case-sensitive)

**Solution**: Verify patterns and paths, then re-run build.

### Injection Step Not Working

**Check**:
- ✓ Verify injection step has correct access to file paths
- ✓ Use `$(Pipeline.Workspace)/$(Build.Repository.Name)/` prefix for file paths
- ✓ Ensure step runs before terraform init

---

## Best Practices

- **Use semantic versions** – Always pin Terraform version for reproducibility
- **Package related files** – Include tfvars, modules, and scripts needed for deployment
- **Validate early** – Use injection steps to catch issues before packaging
- **Consistent naming** – Use clear `ArtifactName` values across your pipelines
- **Test locally** – Validate your Terraform configuration locally before committing

---

## Live Examples

View working test examples in the repository:

- **Basic Build**: [tests/jobs/terraform_build/build_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/jobs/terraform_build/build_test.yml)
- **With Injection Steps**: [tests/jobs/terraform_build/injection_steps_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/jobs/terraform_build/injection_steps_test.yml)
- **With Additional Files**: [tests/jobs/terraform_build/additional_files_test.yml](https://github.com/UKHO/devops-azdo-yaml-pipeline-templates/blob/main/tests/jobs/terraform_build/additional_files_test.yml)

## See Also

- [Terraform Deploy Job](./terraform_deploy.md) – Uses artifact from this job
- [Terraform Gated Deployment Job](./terraform_gated_deployment.md) – Orchestrates build with deploy
- [Terraform Pipeline](../pipelines/terraform_pipeline.md) – Complete pipeline using this job
- [Additional Files Packaging Guide](../pipelines/terraform_pipeline_additional_files_to_package.md) – Detailed guide on file patterns


