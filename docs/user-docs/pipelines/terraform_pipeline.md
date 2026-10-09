# Terraform Pipeline

A standardised infrastructure pipeline that builds, validates, and packages your terraform files, then deploys them to one or more environments with optional [manual verification gates](terraform_pipeline_manual_verification.md).

```yaml
# azure-pipelines.yml
resources:
  repositories:
    - repository: AzDOPipelineTemplates               # REQUIRED: must be named exactly 'AzDOPipelineTemplates'.
      type: github
      endpoint: UKHO                                  # Your GitHub service connection name.
      name: UKHO/devops-azdo-yaml-pipeline-templates
      ref: refs/tags/0.3.1                            # Always pin to a specific version tag.

extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
      # EnvironmentConfigs is the only required parameter - every other value below is shown at its default.

      EnvironmentConfigs:                             # (required, list) One entry per environment. See the EnvironmentConfig docs linked below.
        - Name: dev                                   # Unique environment name.
          Stage:
            DependsOn: Build_Terraform                # Stage dependency.
            Condition: succeeded()                    # Stage execution condition.
          TerraformDeploymentConfig:
            AzDOEnvironmentName: dev-environment      # AzDO Environment for approvals.
            RunMode: PlanVerifyApply                  # PlanVerifyApply, PlanOnly, or ApplyOnly.
            VerificationMode: VerifyOnDestroy         # Required for PlanVerifyApply: VerifyOnDestroy, VerifyOnAny, or VerifyDisabled.

      # RelativePathToTerraformFiles: ''              # Path to terraform files relative to repo root; empty defaults to repo root.
      # TerraformVersion: '1.14.0'                    # Exact terraform version, or 'latest'; wildcards like '1.5.x' are not allowed.
      # AdditionalFilesToPackage:                     # (list) Extra files to bundle into the terraform artifact. Defaults to an empty list.
      # TerraformBuildInjectionSteps:                 # (stepList) Custom steps run before terraform init/validate. Defaults to an empty list.
```

The `EnvironmentConfigs` object is the heart of this pipeline. For its full structure see the [EnvironmentConfig](../../definition_docs/terraform_pipeline/environment_config.md) and [TerraformDeploymentConfig](../../definition_docs/terraform_pipeline/terraform_job_config.md) definition docs, or the [Parameters in Detail](terraform_pipeline_parameters_in_detail.md) guide.

---

## Setup Requirements

- **Repository resource** — You **must** declare the repository resource named exactly `AzDOPipelineTemplates` (shown above); the pipeline checks it out to access helper scripts.
- **Agent pool** — `EnvironmentConfigs` does not expose a per-environment pool. Set a top-level `pool:` in your `azure-pipelines.yml`, or use the job templates directly (`jobs/terraform_build.yml`, `jobs/terraform_deploy.yml`) when you need per-job pool control. Ensure the pool can download the Terraform CLI.
- **Prerequisites** — A Git repo with terraform files, an Azure Resource Manager service connection, a GitHub service connection, and an Azure storage account for terraform state.

---

## What Happens

1. **Build stage** (`Build_Terraform`) — checks out your repo, installs the Terraform CLI, runs `terraform init` (no backend) and `terraform validate`, then packages the files as an artifact.
2. **Deploy stage** (`Deploy_<Name>_Terraform`, one per environment) — downloads the artifact, runs `terraform init` with the backend, runs `terraform plan`, optionally gates on a manual approval per `VerificationMode`, runs `terraform apply`, and exports any `OutputVariables`.

---

## Examples

### Dev + Production with Approval

Deploy to dev automatically, then require approval before production (main branch only):

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: infrastructure/terraform
    TerraformVersion: '1.5.0'
    EnvironmentConfigs:
      - Name: dev
        Stage:
          DependsOn: Build_Terraform
          Condition: succeeded()
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Dev
          AzDOEnvironmentName: development-environment
          BackendConfig:
            resource_group_name: rg-tf-state-dev
            storage_account_name: tfstatedev
            container_name: tfstate
            key: dev.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnDestroy           # Only gate on destructive changes.
          VariableFiles:
            - config/common.tfvars
            - config/dev.tfvars

      - Name: production
        Stage:
          DependsOn: Deploy_dev_Terraform             # Deploy to dev first.
          Condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Prod
          AzDOEnvironmentName: production-environment
          BackendConfig:
            resource_group_name: rg-tf-state-prod
            storage_account_name: tfstateprod
            container_name: tfstate
            key: prod.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnAny               # Always require approval.
          VariableFiles:
            - config/common.tfvars
            - config/prod.tfvars
```

### Plan-Only for Feature Branches

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: infrastructure/terraform
    TerraformVersion: '1.5.0'
    EnvironmentConfigs:
      - Name: precheck
        Stage:
          DependsOn: Build_Terraform
          Condition: and(succeeded(), not(eq(variables['Build.SourceBranch'], 'refs/heads/main')))
        TerraformDeploymentConfig:
          AzDOEnvironmentName: precheck-environment
          RunMode: PlanOnly                           # Only plan, never apply.
          VariableFiles:
            - config/common.tfvars
            - config/precheck.tfvars
```

### Key Vault Secrets and Environment Variables

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    RelativePathToTerraformFiles: infrastructure/terraform
    TerraformVersion: '1.5.0'
    EnvironmentConfigs:
      - Name: production
        Stage:
          DependsOn: Build_Terraform
          Condition: succeeded()
        TerraformDeploymentConfig:
          AzureServiceConnection: AzureServiceConnection-Prod
          AzDOEnvironmentName: production-environment
          BackendConfig:
            resource_group_name: rg-tf-state
            storage_account_name: tfstate
            container_name: tfstate
            key: prod.terraform.tfstate
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnAny
          ConfigSources:
            - Type: KeyVault
              Name: kv-prod-secrets
              ServiceConnection: AzureServiceConnection-Prod
              SecretsFilter: '*'
          EnvironmentVariableMappings:
            TF_LOG: INFO
          JobsVariableMappings:
            - group: ProductionVariables
          VariableFiles:
            - config/common.tfvars
            - config/prod.tfvars
          OutputVariables:
            - resource_group_id
            - app_service_hostname
```

For packaging extra files or injecting a `required_version` constraint, see the
[Additional Files guide](terraform_pipeline_additional_files_to_package.md) and the
[Parameters in Detail](terraform_pipeline_parameters_in_detail.md) guide.

**Live example**: [`tests/pipelines/terraform_pipeline/linux_test.yml`](../../../tests/pipelines/terraform_pipeline/linux_test.yml) (also see [`windows_test.yml`](../../../tests/pipelines/terraform_pipeline/windows_test.yml) and [`elastic_test.yml`](../../../tests/pipelines/terraform_pipeline/elastic_test.yml))

---

## Troubleshooting

**Repository resource not found** (`Repository 'AzDOPipelineTemplates' not found`) — ensure the resource is declared with the exact name `AzDOPipelineTemplates`, the GitHub service connection exists, and it has permission to access the template repository.

**Manual verification not triggering** — `RunMode` must be `PlanVerifyApply` and `VerificationMode` must be `VerifyOnAny` or `VerifyOnDestroy` (not `VerifyDisabled`); the plan must detect changes and the AzDO Environment must have approvers configured. When no changes are detected the plan succeeds, verification is skipped, and apply is skipped — this is expected.

**Output variables unavailable downstream** — outputs are only exported when `RunMode` includes an apply and the names are listed in `OutputVariables`. Reference them with the dependency syntax, for example:

```yaml
variables:
  - name: ResourceGroupId
    value: $[ stageDependencies.Deploy_dev_Terraform.TerraformDeployApply_TerraformArtifact.outputs['TerraformDeployApply_TerraformArtifact.TerraformExportOutputsVariables.rg_id'] ]
```

Use `dependencies.` (same stage) or `stageDependencies.` (later stage), replace `TerraformArtifact` if you set a custom `TerraformArtifactName`, and the final segment with your output variable name.

**Wrong terraform version** — set `TerraformVersion` explicitly to an exact semantic version (e.g. `'1.5.7'`) or `'latest'`; wildcards like `'1.5.x'` are not allowed.

**Backend initialization errors** — verify the storage account and container exist, the service connection has `Storage Blob Data Owner`/`Contributor` on the account, and the `BackendConfig` values are correct.

---

## See Also

- [Parameters in Detail](terraform_pipeline_parameters_in_detail.md) – Every parameter explained
- [Manual Verification Flows](terraform_pipeline_manual_verification.md) – Verification modes
- [Additional Files Packaging](terraform_pipeline_additional_files_to_package.md) – Bundling extra files
- [EnvironmentConfig](../../definition_docs/terraform_pipeline/environment_config.md) – Environment config structure
- [TerraformDeploymentConfig](../../definition_docs/terraform_pipeline/terraform_job_config.md) – Deployment config structure
- [Terraform Build Job](../jobs/terraform_build.md) · [Terraform Deploy Job](../jobs/terraform_deploy.md) – Underlying job templates
