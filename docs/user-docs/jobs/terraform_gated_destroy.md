# Terraform Gated Destroy Job

An orchestrator job template that composes destroy plan, manual verification, and destroy execution.

## When to Use

Use this job template when you need to:

- Run plan-only destroy validation.
- Run direct destroy without manual approval.
- Run gated destroy where manual verification is always required.

## Run Modes

| RunMode | Plan | Manual Verification | Destroy |
| --- | --- | --- | --- |
| `PlanOnly` | Yes | No | No |
| `DestroyOnly` | No | No | Yes |
| `PlanVerifyDestroy` | Yes | Yes (always) | Yes |

`PlanVerifyDestroy` always inserts a manual verification job.

## Basic Usage

```yaml
jobs:
  - template: jobs/terraform_gated_destroy.yml
    parameters:
      EnvironmentName: prod
      TerraformDestroyConfig:
        AzDOEnvironmentName: production-environment
        RunMode: PlanVerifyDestroy
        AzureServiceConnection: AzureServiceConnection-Prod
        BackendConfig:
          resource_group_name: rg-state-prod
          storage_account_name: ststateprod
          container_name: tfstate
          key: prod.tfstate
```

## Parameters

### Required Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `EnvironmentName` | string | Environment identifier |
| `TerraformDestroyConfig` | object | Destroy configuration object |

### Optional Parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `TerraformVersion` | string | `1.14.0` | Terraform CLI version |
| `TerraformArtifactName` | string | `TerraformArtifact` | Artifact name to download |
| `Pool` | string | `''` | Agent pool |
| `DependsOn` | object | `[ ]` | Dependencies for orchestrator-generated jobs |
| `Condition` | string | `succeeded()` | Condition for orchestrator-generated jobs |

## Job Flow

### PlanOnly

- Creates `TerraformDestroyPlan_{Artifact}`.

### DestroyOnly

- Creates `TerraformDestroyDestroy_{Artifact}`.

### PlanVerifyDestroy

1. Creates `TerraformDestroyPlan_{Artifact}`.
2. Creates `ManualVerification_{Artifact}` after plan succeeds.
3. Creates `TerraformDestroyDestroy_{Artifact}` after manual approval.

## Notes

- Manual verification behavior is driven by `RunMode`; there is no `VerificationMode` option for destroy.
- Workflow is artifact-based and does not checkout repositories.

## Live Examples

- [`tests/jobs/terraform_gated_destroy/plan_only_test.yml`](../../../tests/jobs/terraform_gated_destroy/plan_only_test.yml)
- [`tests/jobs/terraform_gated_destroy/destroy_only_test.yml`](../../../tests/jobs/terraform_gated_destroy/destroy_only_test.yml)
- [`tests/jobs/terraform_gated_destroy/plan_verify_destroy_test.yml`](../../../tests/jobs/terraform_gated_destroy/plan_verify_destroy_test.yml)
- [`tests/jobs/terraform_gated_destroy/double_plan_verify_destroy_test.yml`](../../../tests/jobs/terraform_gated_destroy/double_plan_verify_destroy_test.yml)

## See Also

- [Terraform Destroy Job](./terraform_destroy.md)
- [Manual Verification Job](./manual_verification.md)
- [Terraform Destroy Config Definition](../../definition_docs/terraform_pipeline/terraform_destroy_config.md)
