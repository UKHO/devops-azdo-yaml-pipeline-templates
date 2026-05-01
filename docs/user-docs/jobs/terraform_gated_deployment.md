# Terraform Gated Deployment Job

An orchestrator job template that combines terraform plan, manual verification, and terraform apply jobs into a cohesive deployment workflow. This job handles the complete infrastructure deployment cycle with configurable run modes and automatic gate logic.

---

## When to Use

Use this job template when you need to:

- **Complete deployments** – Plan, verify (optionally), and apply in one stage
- **Flexible verification** – Configure different approval strategies per environment
- **Multi-mode support** – Support plan-only, apply-only, or full cycle deployments
- **Automatic orchestration** – Job automatically creates sub-jobs based on configuration

**Best for**: Deployment stages in infrastructure pipelines where you want complete infrastructure provisioning control.

---

## What This Job Does

Based on the `RunMode` configuration, this job creates one to three sub-jobs:

### PlanOnly Mode
- Creates **Plan job** that shows infrastructure changes
- Skips manual verification
- Skips apply job
- Useful for dry-run validation on feature branches

### ApplyOnly Mode
- Skips plan phase
- Creates **Apply job** that directly provisions infrastructure
- No manual verification
- Useful for environments with automated trust (e.g., dev)

### PlanVerifyApply Mode (Default)
- Creates **Plan job** to show infrastructure changes
- Creates **Manual Verification job** (conditional based on changes detected)
- Creates **Apply job** to provision infrastructure
- Verification gate is conditional based on `VerificationMode`

---

## Basic Usage

```yaml
stages:
  - stage: DeployDev
    dependsOn: Build
    jobs:
      - template: jobs/terraform_gated_deployment.yml
        parameters:
          EnvironmentName: dev
          TerraformVersion: '1.5.0'
          TerraformDeploymentConfig:
            AzDOEnvironmentName: dev-environment
            RunMode: PlanVerifyApply
            VerificationMode: VerifyOnDestroy
            BackendConfig:
              resource_group_name: rg-state-dev
              storage_account_name: tfstatedev
              container_name: tfstate
              key: dev.tfstate
            AzureServiceConnection: AzureServiceConnection-Dev
            VariableFiles:
              - config/common.tfvars
              - config/dev.tfvars
```

---

## Parameters

### Required Parameters

| Parameter                   | Type   | Description                                                                  |
|-----------------------------|--------|------------------------------------------------------------------------------|
| `EnvironmentName`           | string | Environment identifier (e.g., `dev`, `prod`) – used in job names and outputs |
| `TerraformDeploymentConfig` | object | Complete terraform deployment configuration (see below)                      |

### Optional Parameters

| Parameter               | Type   | Default                 | Description                             |
|-------------------------|--------|-------------------------|-----------------------------------------|
| `TerraformVersion`      | string | `1.14.0`                | Terraform CLI version                   |
| `TerraformArtifactName` | string | `TerraformArtifact`     | Name of artifact from build stage       |
| `Pool`                  | string | `''`                    | Agent pool for jobs                     |
| `CheckoutAlias`         | string | `AzDOPipelineTemplates` | Repository alias for template checkout  |
| `DependsOn`             | object | `[ ]`                   | Jobs this orchestrator depends on       |
| `Condition`             | string | `succeeded()`           | Condition for running this orchestrator |

### TerraformDeploymentConfig (Required)

| Property                      | Type   | Required                          | Description                                                |
|-------------------------------|--------|-----------------------------------|------------------------------------------------------------|
| `RunMode`                     | string | ✓                                 | One of: `PlanVerifyApply`, `PlanOnly`, `ApplyOnly`         |
| `AzDOEnvironmentName`         | string | ✓                                 | Azure DevOps environment for approvals                     |
| `VerificationMode`            | string | When RunMode is `PlanVerifyApply` | One of: `VerifyOnDestroy`, `VerifyOnAny`, `VerifyDisabled` |
| `BackendConfig`               | object | Optional                          | Terraform backend configuration (key-value pairs)          |
| `AzureServiceConnection`      | string | Optional                          | Azure service connection for authentication                |
| `EnvironmentVariableMappings` | object | Optional                          | Environment variables for Terraform                        |
| `VariableFiles`               | list   | Optional                          | List of `.tfvars` files (relative to artifact)             |
| `OutputVariables`             | list   | Optional                          | Terraform outputs to export as variables                   |
| `KeyVaultConfig`              | object | Optional                          | Key Vault configuration                                    |
| `JobsVariableMappings`        | object | Optional                          | Variable groups or inline variables                        |

---

## Examples

### PlanOnly Mode (Feature Branch Validation)

Validate changes without applying:

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

### ApplyOnly Mode (Development Auto-Deploy)

Automatically apply changes in dev environment:

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

### VerifyOnDestroy (Production Safe Apply)

Only gate if infrastructure will be destroyed:

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

Gate all infrastructure changes:

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
        KeyVaultConfig:
          ServiceConnection: AzureServiceConnection-Prod
          Name: kv-prod
          SecretsFilter: '*'
        JobsVariableMappings:
          - group: ProductionSecrets
        VariableFiles:
          - config/common.tfvars
          - config/prod.tfvars
```

### VerifyDisabled (Auto-Apply Mode)

Apply changes automatically, no approval:

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

---

## How Verification Works

### VerifyOnDestroy

Manual approval is triggered **only if** Terraform plan shows resources being destroyed:

```
Plan → Analyze (detect destroys?) → Manual Approval → Apply
           ↓ (no destroys)
           → Apply (no approval needed)
```

**Use when**: You want to prevent accidental deletion but allow non-destructive changes to apply automatically.

### VerifyOnAny

Manual approval is triggered if **any** infrastructure changes are detected:

```
Plan → Analyze (any changes?) → Manual Approval → Apply
           ↓ (no changes)
           → Success (nothing to apply)
```

**Use when**: All infrastructure changes require explicit approval.

### VerifyDisabled

No approval gate – apply automatically:

```
Plan → Analyze → Apply
    (approval disabled)
```

**Use when**: Environment is trusted (dev) or automated approval exists elsewhere.

---

## Job Dependencies

The orchestrator automatically manages dependencies between generated jobs:

```
Plan Job
   ↓
Manual Verification Job (conditional)
   ↓
Apply Job
```

Manual verification job only runs if:
- Changes detected in plan
- `VerificationMode` determines it needs approval

Apply job runs only if:
- No changes + no verification needed
- OR approval was granted

---

## Troubleshooting

### Manual Verification Not Appearing

**Check**:
- ✓ Verify `RunMode` is `PlanVerifyApply` (not `PlanOnly` or `ApplyOnly`)
- ✓ Verify `VerificationMode` is set correctly
- ✓ Check that plan detected changes
- ✓ Verify AzDO environment exists

### Apply Never Runs

**Possible causes**:
- Approval was rejected → Expected, pipeline stops
- Timeout occurred → Check timeout setting
- No terraform changes detected → Expected, nothing to apply

**Check**:
- ✓ Review manual verification approval status
- ✓ Check plan job output for detected changes
- ✓ Verify approval was actually granted

### Output Variables Not Available

**Cause**: Variables only available after successful apply.

**Check**:
- ✓ Ensure `RunMode` includes apply operation
- ✓ Verify `OutputVariables` are defined in config
- ✓ Use correct variable reference syntax

---

## Best Practices

- **Choose right VerificationMode** – Match your deployment control level
- **Use job dependencies** – Include build stage in `DependsOn`
- **Export outputs** – Define `OutputVariables` for downstream usage
- **Consistent naming** – Use clear environment names
- **Test modes** – Test each mode (PlanOnly, ApplyOnly) before production
- **Document gates** – Include gate strategy in deployment documentation

---

## Comparison with Other Jobs

| Job                     | Plan Job | Manual Verification | Apply Job | Use Case          |
|-------------------------|----------|---------------------|-----------|-------------------|
| **Terraform Deploy**    | ✓        | ✗                   | ✓         | Individual steps  |
| **Manual Verification** | ✗        | ✓                   | ✗         | Generic approval  |
| **Gated Deployment**    | ✓        | ✓                   | ✓         | Complete workflow |

---

## See Also

- [Terraform Deploy Job](./terraform_deploy.md) – Individual plan and apply steps
- [Manual Verification Job](./manual_verification.md) – Approval gate details
- [Terraform Pipeline](../pipelines/terraform_pipeline.md) – Complete pipeline using this job
- [Terraform Verification Modes](../pipelines/terraform_pipeline_manual_verification.md) – Detailed verification flow diagrams


