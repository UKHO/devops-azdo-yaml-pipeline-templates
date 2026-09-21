# Terraform Destroy Job

A reusable job template that executes Terraform destroy operations against a previously published Terraform artifact. Runs either a destroy plan step or a direct destroy step.

```yaml
jobs:
  - template: jobs/terraform_destroy.yml
    parameters:
      # Required - no defaults
      EnvironmentName: dev                          # Environment identifier; used in job naming.
      TerraformDestroyConfig:                       # Destroy configuration object.
        # Required
        AzDOEnvironmentName: dev-environment        # Azure DevOps environment for approval gates.

        # Optional
        # BackendConfig:                            # (object) Terraform backend configuration (key-value pairs).
        # AzureServiceConnection: ''                # Azure service connection for authentication.
        # ConfigSources:                            # (list) Ordered configuration sources (currently Type: KeyVault). Example item structure:
        #   - Type: KeyVault
        #     Name: kv-secrets
        #     ServiceConnection: AzureServiceConnection-Prod
        #     SecretsFilter: '*'
        # JobsVariableMappings:                     # (list) Variable groups, templates, or inline variables to inject.
        # EnvironmentVariableMappings:              # (object) Environment variables for the terraform task (e.g., TF_LOG).
        # VariableFiles:                            # (list) .tfvars files relative to the artifact root.

      # Optional - shown at their defaults. Uncomment and change a value to override it.
      # TerraformDestroyMode: Plan                  # 'Plan' or 'Destroy' - determines which terraform command runs.
      # TerraformVersion: '1.14.0'                  # Terraform CLI version, or 'latest'; wildcards like '1.5.x' are not allowed.
      # TerraformArtifactName: 'TerraformArtifact'  # Name of the artifact to download for destroy.
      # Pool: ''                                    # Agent pool to run this job on; empty uses the pipeline/stage default pool.
      # DependsOn:                                  # (list) Jobs this job depends on.
      # Condition: succeeded()                      # Condition controlling whether this job runs.
```

`KeyVaultConfig` is not supported for destroy workflows – use `ConfigSources` instead. `VerificationMode` is also not supported here.

---

## Examples

### Plan Destroy

```yaml
jobs:
  - template: jobs/terraform_destroy.yml
    parameters:
      TerraformDestroyMode: Plan
      EnvironmentName: staging
      TerraformVersion: '1.5.0'
      TerraformDestroyConfig:
        AzDOEnvironmentName: staging-environment
        BackendConfig:
          resource_group_name: rg-state-staging
          storage_account_name: ststatestaging
          container_name: tfstate
          key: staging.tfstate
        VariableFiles:
          - config/common.tfvars
          - config/staging.tfvars
```

**Live example**: [`tests/jobs/terraform_destroy/plan_only_test.yml`](../../../tests/jobs/terraform_destroy/plan_only_test.yml) (also see [`plan_with_variable_files_test.yml`](../../../tests/jobs/terraform_destroy/plan_with_variable_files_test.yml))

### Destroy with Azure Service Connection

```yaml
jobs:
  - template: jobs/terraform_destroy.yml
    parameters:
      TerraformDestroyMode: Destroy
      EnvironmentName: prod
      TerraformDestroyConfig:
        AzDOEnvironmentName: production-environment
        AzureServiceConnection: AzureServiceConnection-Prod
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: ststateprod
          container_name: tfstate
          key: prod.tfstate
        VariableFiles:
          - config/prod.tfvars
```

**Live example**: [`tests/jobs/terraform_destroy/destroy_only_test.yml`](../../../tests/jobs/terraform_destroy/destroy_only_test.yml)

### Destroy with Key Vault (ConfigSources)

```yaml
jobs:
  - template: jobs/terraform_destroy.yml
    parameters:
      TerraformDestroyMode: Destroy
      EnvironmentName: prod
      TerraformDestroyConfig:
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
```

**Live example**: [`tests/jobs/terraform_destroy/destroy_with_configsources_test.yml`](../../../tests/jobs/terraform_destroy/destroy_with_configsources_test.yml)

---

## See Also

- [Terraform Gated Destroy Job](./terraform_gated_destroy.md)
- [Terraform Build Job](./terraform_build.md)
- [Terraform Deploy Job](./terraform_deploy.md)
