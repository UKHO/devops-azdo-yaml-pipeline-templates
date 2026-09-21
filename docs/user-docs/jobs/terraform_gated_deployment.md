# Terraform Gated Deployment Job

An orchestrator job template that combines terraform plan, manual verification, and terraform apply jobs into a cohesive deployment workflow, with automatic gate logic based on the configured run mode.

```yaml
jobs:
  - template: jobs/terraform_gated_deployment.yml
    parameters:
      # Required - no defaults
      EnvironmentName: dev                          # Environment identifier; used in generated job names and outputs.
      TerraformDeploymentConfig:                    # Deployment configuration object.
        # Required
        AzDOEnvironmentName: dev-environment        # Azure DevOps environment for deployment association.
        RunMode: PlanVerifyApply                    # One of: PlanVerifyApply, PlanOnly, ApplyOnly.

        # Required when RunMode is PlanVerifyApply
        # VerificationMode: VerifyOnDestroy         # One of: VerifyOnDestroy, VerifyOnAny, VerifyDisabled.

        # Optional - used only when RunMode is PlanVerifyApply
        # VerificationTimeoutInMinutes: 60          # Number between 1 and 43200 (30 days).
        # VerificationTimeoutBehaviour: reject      # 'reject' or 'resume'.

        # Optional
        # BackendConfig:                            # (object) Terraform backend configuration (key-value pairs).
        # AzureServiceConnection: ''                # Azure service connection for authentication. Must be known at compile time.
        # EnvironmentVariableMappings:              # (object) Environment variables for Terraform.
        # VariableFiles:                            # (list) .tfvars files (relative to artifact).
        # OutputVariables:                          # (list) Terraform outputs to export as variables.
        # ConfigSources:                            # (list) Configuration sources (currently Type: KeyVault, preferred, array-based).
        # KeyVaultConfig:                           # (object) Key Vault configuration (legacy - use ConfigSources for new deployments).
        # JobsVariableMappings:                     # (list) Variable groups or inline variables.

      # Optional - shown at their defaults. Uncomment and change a value to override it.
      # TerraformVersion: '1.14.0'                  # Terraform CLI version, or 'latest'; wildcards like '1.5.x' are not allowed.
      # TerraformArtifactName: 'TerraformArtifact'  # Name of artifact from the build stage.
      # Pool: ''                                    # Agent pool for generated jobs; empty uses the pipeline/stage default pool.
      # CheckoutAlias: 'AzDOPipelineTemplates'      # Repository alias used to check out this template repo for output/verification scripts. Internal usage only.
      # DependsOn:                                  # (list) Jobs this orchestrator depends on.
      # Condition: succeeded()                      # Condition controlling whether this orchestrator runs.
```

---

## What This Job Does

Based on the `RunMode` configuration, this job creates one to three sub-jobs:

| RunMode            | Plan | Manual Verification    | Apply |
|----------------------|------|--------------------------|-------|
| `PlanOnly`           | Yes  | No                       | No    |
| `ApplyOnly`          | No   | No                       | Yes   |
| `PlanVerifyApply`    | Yes  | Conditional (see below)  | Yes   |

For `PlanVerifyApply`, the manual verification job only runs if the plan detects changes **and** `VerificationMode` determines approval is required:

- **`VerifyOnDestroy`** – approval only triggered if the plan shows resources being destroyed
- **`VerifyOnAny`** – approval triggered if any infrastructure changes are detected
- **`VerifyDisabled`** – no approval gate, apply runs automatically

```text
Plan Job
   ↓
Manual Verification Job (conditional)
   ↓
Apply Job
```

---

## Examples

### PlanOnly Mode (Feature Branch Validation)

```yaml
jobs:
  - template: jobs/terraform_gated_deployment.yml
    parameters:
      EnvironmentName: validation
      TerraformDeploymentConfig:
        AzDOEnvironmentName: validation-environment
        RunMode: PlanOnly  # Only plan, no apply
        BackendConfig:
          resource_group_name: rg-state
          storage_account_name: tfstate
          container_name: tfstate
          key: validation.tfstate
```

**Live example**: [`tests/jobs/terraform_gated_deployment/plan_only_test.yml`](../../../tests/jobs/terraform_gated_deployment/plan_only_test.yml) (also see [`double_plan_only_test.yml`](../../../tests/jobs/terraform_gated_deployment/double_plan_only_test.yml))

### ApplyOnly Mode (Development Auto-Deploy)

```yaml
jobs:
  - template: jobs/terraform_gated_deployment.yml
    parameters:
      EnvironmentName: dev
      TerraformDeploymentConfig:
        AzDOEnvironmentName: dev-environment
        RunMode: ApplyOnly  # Skip plan, auto-apply
        AzureServiceConnection: AzureServiceConnection-Dev
        BackendConfig:
          resource_group_name: rg-state-dev
          storage_account_name: tfstatedev
          container_name: tfstate
          key: dev.tfstate
        VariableFiles:
          - config/common.tfvars
          - config/dev.tfvars
```

**Live example**: [`tests/jobs/terraform_gated_deployment/apply_only_test.yml`](../../../tests/jobs/terraform_gated_deployment/apply_only_test.yml) (also see [`double_apply_only_test.yml`](../../../tests/jobs/terraform_gated_deployment/double_apply_only_test.yml))

### VerifyOnDestroy (Production Safe Apply)

```yaml
jobs:
  - template: jobs/terraform_gated_deployment.yml
    parameters:
      EnvironmentName: prod
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        RunMode: PlanVerifyApply
        VerificationMode: VerifyOnDestroy  # Only approve if resources deleted
        AzureServiceConnection: AzureServiceConnection-Prod
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: tfstateprod
          container_name: tfstate
          key: prod.tfstate
        VariableFiles:
          - config/common.tfvars
          - config/prod.tfvars
        OutputVariables:
          - app_service_url
```

### VerifyOnAny (Strict Production Control)

```yaml
jobs:
  - template: jobs/terraform_gated_deployment.yml
    parameters:
      EnvironmentName: prod
      DependsOn:
        - BuildStage
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        RunMode: PlanVerifyApply
        VerificationMode: VerifyOnAny  # Approve all changes
        AzureServiceConnection: AzureServiceConnection-Prod
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: tfstateprod
          container_name: tfstate
          key: prod.tfstate
        ConfigSources:
          - Type: KeyVault
            Name: kv-prod
            ServiceConnection: AzureServiceConnection-Prod
            SecretsFilter: '*'
        JobsVariableMappings:
          - group: ProductionSecrets
        VariableFiles:
          - config/common.tfvars
          - config/prod.tfvars
```

**Live example**: [`tests/jobs/terraform_gated_deployment/plan_verify_apply_test.yml`](../../../tests/jobs/terraform_gated_deployment/plan_verify_apply_test.yml) (also see [`double_plan_verify_apply_test.yml`](../../../tests/jobs/terraform_gated_deployment/double_plan_verify_apply_test.yml))

### VerifyDisabled (Auto-Apply Mode)

```yaml
jobs:
  - template: jobs/terraform_gated_deployment.yml
    parameters:
      EnvironmentName: staging
      TerraformDeploymentConfig:
        AzDOEnvironmentName: staging-environment
        RunMode: PlanVerifyApply
        VerificationMode: VerifyDisabled  # Auto-apply without approval
        AzureServiceConnection: AzureServiceConnection-Staging
        BackendConfig:
          resource_group_name: rg-state-staging
          storage_account_name: stfstatestaging
          container_name: tfstate
          key: staging.tfstate
        VariableFiles:
          - config/common.tfvars
          - config/staging.tfvars
```

**Live example**: [`tests/jobs/terraform_gated_deployment/plan_verify_apply_verify_disabled_test.yml`](../../../tests/jobs/terraform_gated_deployment/plan_verify_apply_verify_disabled_test.yml)

### Overriding the Manual Verification Timeout

```yaml
jobs:
  - template: jobs/terraform_gated_deployment.yml
    parameters:
      EnvironmentName: prod
      TerraformDeploymentConfig:
        AzDOEnvironmentName: production-environment
        RunMode: PlanVerifyApply
        VerificationMode: VerifyOnAny
        VerificationTimeoutInMinutes: 240
        VerificationTimeoutBehaviour: resume
```

---

## Comparison with Other Jobs

| Job                     | Plan Job | Manual Verification | Apply Job | Use Case          |
|-------------------------|----------|----------------------|-----------|--------------------|
| **Terraform Deploy**    | ✓        | ✗                    | ✓         | Individual steps  |
| **Manual Verification** | ✗        | ✓                    | ✗         | Generic approval  |
| **Gated Deployment**    | ✓        | ✓                    | ✓         | Complete workflow |

---

## See Also

- [Terraform Deploy Job](./terraform_deploy.md)
- [Manual Verification Job](./manual_verification.md)
- [Terraform Gated Destroy Job](./terraform_gated_destroy.md)
- [Terraform Pipeline](../pipelines/terraform_pipeline.md)
- [Terraform Verification Modes](../pipelines/terraform_pipeline_manual_verification.md)
