# Terraform Gated Destroy Job

An orchestrator job template that composes destroy plan, manual verification, and destroy execution into a cohesive teardown workflow.

```yaml
jobs:
  - template: jobs/terraform_gated_destroy.yml
    parameters:
      # Required - no defaults
      EnvironmentName: prod                         # Environment identifier; used in generated job names.
      TerraformDestroyConfig:                       # Destroy configuration object.
        # Required
        AzDOEnvironmentName: production-environment # Azure DevOps environment for deployment association.
        RunMode: PlanVerifyDestroy                  # One of: PlanOnly, DestroyOnly, PlanVerifyDestroy.

        # Optional - used only when RunMode is PlanVerifyDestroy
        # VerificationTimeoutInMinutes: 60          # Number between 1 and 43200 (30 days).
        # VerificationTimeoutBehaviour: reject      # 'reject' or 'resume'.

        # Optional
        # BackendConfig:                            # (object) Terraform backend configuration (key-value pairs).
        # AzureServiceConnection: ''                # Azure service connection for authentication. Must be known at compile time.
        # ConfigSources:                            # (list) Ordered configuration sources (currently Type: KeyVault).
        # JobsVariableMappings:                     # (list) Variable groups, templates, or inline variables.
        # EnvironmentVariableMappings:              # (object) Environment variables for the terraform task.
        # VariableFiles:                            # (list) .tfvars files relative to the artifact root.

      # Optional - shown at their defaults. Uncomment and change a value to override it.
      # TerraformVersion: '1.14.0'                  # Terraform CLI version, or 'latest'; wildcards like '1.5.x' are not allowed.
      # TerraformArtifactName: 'TerraformArtifact'  # Name of artifact from the build stage.
      # Pool: ''                                    # Agent pool for generated jobs; empty uses the pipeline/stage default pool.
      # DependsOn:                                  # (list) Jobs this orchestrator depends on.
      # Condition: succeeded()                      # Condition controlling whether this orchestrator runs.
```

There is no `VerificationMode` option for destroy – verification behavior is driven entirely by `RunMode`. `KeyVaultConfig` is not supported; use `ConfigSources`.

---

## What This Job Does

Based on the `RunMode` configuration, this job creates one to three sub-jobs:

| RunMode               | Plan | Manual Verification | Destroy |
|------------------------|------|-----------------------|---------|
| `PlanOnly`             | Yes  | No                    | No      |
| `DestroyOnly`          | No   | No                    | Yes     |
| `PlanVerifyDestroy`    | Yes  | Yes (always)          | Yes     |

The manual verification job for `PlanVerifyDestroy` is **always** inserted – it is never conditional on the plan's detected changes.

```text
Plan Job (TerraformDestroyPlan_{Artifact})
   ↓
Manual Verification Job (ManualVerification_{Artifact})  # always created for PlanVerifyDestroy
   ↓
Destroy Job (TerraformDestroyDestroy_{Artifact})
```

---

## Examples

### PlanOnly Mode (Dry-Run Validation)

```yaml
jobs:
  - template: jobs/terraform_gated_destroy.yml
    parameters:
      EnvironmentName: validation
      TerraformDestroyConfig:
        AzDOEnvironmentName: validation-environment
        RunMode: PlanOnly  # Only plan-destroy, no destroy
        BackendConfig:
          resource_group_name: rg-state
          storage_account_name: tfstate
          container_name: tfstate
          key: validation.tfstate
```

**Live example**: [`tests/jobs/terraform_gated_destroy/plan_only_test.yml`](../../../tests/jobs/terraform_gated_destroy/plan_only_test.yml)

### DestroyOnly Mode (Ephemeral Environment Teardown)

```yaml
jobs:
  - template: jobs/terraform_gated_destroy.yml
    parameters:
      EnvironmentName: pr-1234
      TerraformDestroyConfig:
        AzDOEnvironmentName: pr-environment
        RunMode: DestroyOnly  # Skip plan and verification
        AzureServiceConnection: AzureServiceConnection-Dev
        BackendConfig:
          resource_group_name: rg-state-pr
          storage_account_name: tfstatepr
          container_name: tfstate
          key: pr-1234.tfstate
```

**Live example**: [`tests/jobs/terraform_gated_destroy/destroy_only_test.yml`](../../../tests/jobs/terraform_gated_destroy/destroy_only_test.yml)

### PlanVerifyDestroy Mode (Gated Production Teardown)

```yaml
jobs:
  - template: jobs/terraform_gated_destroy.yml
    parameters:
      EnvironmentName: prod
      DependsOn:
        - BuildStage
      TerraformDestroyConfig:
        AzDOEnvironmentName: production-environment
        RunMode: PlanVerifyDestroy
        AzureServiceConnection: AzureServiceConnection-Prod
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: ststateprod
          container_name: tfstate
          key: prod.tfstate
        ConfigSources:
          - Type: KeyVault
            Name: kv-prod
            ServiceConnection: AzureServiceConnection-Prod
            SecretsFilter: '*'
        VariableFiles:
          - config/common.tfvars
          - config/prod.tfvars
```

**Live example**: [`tests/jobs/terraform_gated_destroy/plan_verify_destroy_test.yml`](../../../tests/jobs/terraform_gated_destroy/plan_verify_destroy_test.yml) (also see [`double_plan_verify_destroy_test.yml`](../../../tests/jobs/terraform_gated_destroy/double_plan_verify_destroy_test.yml))

### Overriding the Manual Verification Timeout

```yaml
jobs:
  - template: jobs/terraform_gated_destroy.yml
    parameters:
      EnvironmentName: prod
      TerraformDestroyConfig:
        AzDOEnvironmentName: production-environment
        RunMode: PlanVerifyDestroy
        VerificationTimeoutInMinutes: 240
        VerificationTimeoutBehaviour: resume
```

---

## See Also

- [Terraform Destroy Job](./terraform_destroy.md)
- [Manual Verification Job](./manual_verification.md)
- [Terraform Gated Deployment Job](./terraform_gated_deployment.md)
- [Terraform Pipeline](../pipelines/terraform_pipeline.md)
