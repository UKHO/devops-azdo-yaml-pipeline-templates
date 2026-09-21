# Terraform Deploy Job

A job template for individual Terraform deployment steps. Runs either the plan phase (showing what will change) or the apply phase (provisioning infrastructure), with support for environment variables, Key Vault integration, and output variable extraction.

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      # Required - no defaults
      TerraformDeployMode: Plan                        # 'Plan' or 'Apply' - determines which terraform command runs.
      EnvironmentName: dev                             # Environment identifier; used in job naming and outputs.
      TerraformDeploymentConfig:                       # Deployment configuration object.
        # Required
        AzDOEnvironmentName: dev-environment           # Azure DevOps environment for approval gates.

        # Optional
        # VerificationMode: VerifyOnDestroy            # One of: VerifyOnDestroy, VerifyOnAny, VerifyDisabled. When provided, adds plan-verification steps.
        # BackendConfig:                               # (object) Terraform backend configuration (key-value pairs).
        # AzureServiceConnection: ''                   # Azure service connection for authentication.
        # EnvironmentVariableMappings:                 # (object) Environment variables for Terraform (e.g., TF_LOG).
        # VariableFiles:                               # (list) .tfvars files to use (paths relative to artifact).
        # OutputVariables:                             # (list) Terraform output names to export as pipeline variables.
        # ConfigSources:                               # (list) Configuration sources (currently Type: KeyVault, preferred). Example item structure:
        #   - Type: KeyVault
        #     Name: kv-secrets
        #     ServiceConnection: AzureServiceConnection-Prod
        #     SecretsFilter: '*'
        # KeyVaultConfig:                              # (object) Azure Key Vault configuration (legacy - mutually exclusive with ConfigSources). Example:
        #   ServiceConnection: AzureServiceConnection-Prod
        #   Name: kv-secrets
        #   SecretsFilter: '*'
        # JobsVariableMappings:                        # (list) Variable groups, templates, or inline variables to inject.

      # Optional - shown at their defaults. Uncomment and change a value to override it.
      # TerraformVersion: '1.14.0'                     # Terraform CLI version, or 'latest'; wildcards like '1.5.x' are not allowed.
      # TerraformArtifactName: 'TerraformArtifact'     # Name of artifact to download from the build stage.
      # Pool: ''                                       # Agent pool to run this job on; empty uses the pipeline/stage default pool.
      # CheckoutAlias: 'AzDOPipelineTemplates'         # Repository alias used to check out this template repo for output/verification scripts.
      # DependsOn:                                     # (list) Jobs this job depends on.
      # Condition: succeeded()                         # Condition controlling whether this job runs.
```

`KeyVaultConfig` and `ConfigSources` are mutually exclusive. Use `ConfigSources` for new configurations.

---

## Output Variables

When `OutputVariables` are configured, Terraform outputs are exported as pipeline variables available to later jobs in the same stage or jobs in later stages.

Same stage syntax:

```yaml
variables:
  - name: ResourceGroupName
    value: $[ dependencies.TerraformDeployApply_TerraformArtifact.outputs['TerraformDeployApply_TerraformArtifact.TerraformExportOutputsVariables.resource_group_name'] ]
```

Later stage syntax:

```yaml
variables:
  - name: ResourceGroupName
    value: $[ stageDependencies.Deploy_prod_Terraform.TerraformDeployApply_TerraformArtifact.outputs['TerraformDeployApply_TerraformArtifact.TerraformExportOutputsVariables.resource_group_name'] ]
```

Replace:

- `Deploy_prod_Terraform` with your stage name
- `dependencies` (same stage) or `stageDependencies` (cross-stage), depending on where you consume the variable
- if using a non-default `TerraformArtifactName`, replace `TerraformArtifact` in `TerraformDeployApply_TerraformArtifact` with your artifact name
- `resource_group_name` with your output variable name

---

## Examples

### Plan with Environment Variables

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Plan
      EnvironmentName: staging
      TerraformVersion: '1.5.0'
      TerraformDeploymentConfig:
        AzDOEnvironmentName: staging-environment
        VerificationMode: VerifyOnDestroy
        BackendConfig:
          resource_group_name: rg-state-staging
          storage_account_name: ststatestaging
          container_name: tfstate
          key: staging.tfstate
        AzureServiceConnection: AzureServiceConnection-Staging
        EnvironmentVariableMappings:
          TF_LOG: DEBUG
          ARM_SKIP_PROVIDER_REGISTRATION: 'true'
        VariableFiles:
          - config/common.tfvars
          - config/staging.tfvars
```

**Live example**: [`tests/jobs/terraform_deploy/plan_with_multiple_mappings_test.yml`](../../../tests/jobs/terraform_deploy/plan_with_multiple_mappings_test.yml) (also see [`plan_basic_test.yml`](../../../tests/jobs/terraform_deploy/plan_basic_test.yml) and [`plan_with_verify_mode_test.yml`](../../../tests/jobs/terraform_deploy/plan_with_verify_mode_test.yml))

### Apply with Variable Groups and Outputs

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Apply
      EnvironmentName: prod
      DependsOn:
        - ApprovalJob
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: ststateprod
          container_name: tfstate
          key: prod.tfstate
        AzureServiceConnection: AzureServiceConnection-Prod
        JobsVariableMappings:
          - group: ProductionSecrets
        VariableFiles:
          - config/common.tfvars
          - config/prod.tfvars
        OutputVariables:
          - resource_group_id
          - app_service_url
```

**Live example**: [`tests/jobs/terraform_deploy/apply_with_multiple_mappings_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_multiple_mappings_test.yml) (also see [`apply_with_outputs_same_stage_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_outputs_same_stage_test.yml) and [`apply_with_outputs_future_stage_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_outputs_future_stage_test.yml))

### Apply with Key Vault (ConfigSources)

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Apply
      EnvironmentName: prod
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        AzureServiceConnection: AzureServiceConnection-Prod
        ConfigSources:
          - Type: KeyVault
            Name: kv-prod-secrets
            ServiceConnection: AzureServiceConnection-Prod
            SecretsFilter: '*'
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: ststateprod
          container_name: tfstate
          key: prod.tfstate
        VariableFiles:
          - config/prod.tfvars
        OutputVariables:
          - app_service_hostname
```

**Live example**: [`tests/jobs/terraform_deploy/apply_with_configsources_one_key_vault_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_configsources_one_key_vault_test.yml) (also see [`apply_with_configsources_two_key_vault_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_configsources_two_key_vault_test.yml) for multiple vaults)

### Apply with Key Vault (Legacy)

```yaml
jobs:
  - template: jobs/terraform_deploy.yml
    parameters:
      TerraformDeployMode: Apply
      EnvironmentName: prod
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        AzureServiceConnection: AzureServiceConnection-Prod
        KeyVaultConfig:
          ServiceConnection: AzureServiceConnection-Prod
          Name: kv-prod-secrets
          SecretsFilter: '*'
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: ststateprod
          container_name: tfstate
          key: prod.tfstate
        VariableFiles:
          - config/prod.tfvars
        OutputVariables:
          - app_service_hostname
```

**Live example**: [`tests/jobs/terraform_deploy/apply_with_legacy_key_vault_test.yml`](../../../tests/jobs/terraform_deploy/apply_with_legacy_key_vault_test.yml)

### Plan + Apply Sequence

**Live example**: [`tests/jobs/terraform_deploy/plan_apply_basic_test.yml`](../../../tests/jobs/terraform_deploy/plan_apply_basic_test.yml) (also see [`double_plan_basic_test.yml`](../../../tests/jobs/terraform_deploy/double_plan_basic_test.yml) and [`double_apply_basic_test.yml`](../../../tests/jobs/terraform_deploy/double_apply_basic_test.yml) for running two plans/applies in one pipeline)

---

## See Also

- [Terraform Gated Deployment Job](./terraform_gated_deployment.md)
- [Terraform Build Job](./terraform_build.md)
- [Terraform Destroy Job](./terraform_destroy.md)
- [Terraform Pipeline](../pipelines/terraform_pipeline.md)
- [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends)
