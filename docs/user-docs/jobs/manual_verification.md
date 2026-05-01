# Manual Verification Job

A reusable job template that provides manual approval gates in Azure DevOps pipelines. This job wraps the Azure DevOps `ManualValidation@1` task with flexible configuration for notifications, approvers, and timeout behavior.

---

## When to Use

Use this job template when you need to pause a pipeline for manual review and approval. Common scenarios include:

- **Approval before deployment** – Gate infrastructure changes before applying
- **Sign-off workflows** – Require stakeholder approval before proceeding
- **Multi-stage verification** – Progressive approval through multiple environments
- **Change management** – Integrate with your change control process

---

## Basic Usage

```yaml
stages:
  - stage: Deploy
    jobs:
      - template: jobs/manual_verification.yml
        parameters:
          JobName: ApproveDeployment
          DependsOn: []
          Instructions: 'Please review the terraform plan and approve if acceptable'
          TimeoutInMinutes: 120
```

---

## Parameters

### Required Parameters

None – all parameters have sensible defaults.

### Optional Parameters

| Parameter            | Type   | Default              | Description                                                                            |
|----------------------|--------|----------------------|----------------------------------------------------------------------------------------|
| `JobName`            | string | `ManualVerification` | Name of the job for identification in pipeline logs                                    |
| `DependsOn`          | object | `[ ]`                | List of jobs this job depends on. Causes this job to wait for those jobs to complete   |
| `Condition`          | string | `succeeded()`        | Condition determining whether this job runs (e.g., only run if previous job succeeded) |
| `OnTimeoutBehaviour` | string | `reject`             | Action on timeout: `reject` (fail) or `resume` (auto-approve)                          |
| `TimeoutInMinutes`   | number | `60`                 | Timeout duration in minutes (max 30 days = 43200 minutes)                              |
| `Instructions`       | string | `''`                 | Instructions displayed to approvers explaining what they're approving                  |

---

## Examples

### Simple Approval Gate

```yaml
jobs:
  - template: jobs/manual_verification.yml
    parameters:
      JobName: ManualApproval
      Instructions: 'Review the deployment and approve to proceed'
```

### Approval with Timeout

```yaml
jobs:
  - template: jobs/manual_verification.yml
    parameters:
      JobName: ProductionApproval
      DependsOn:
        - BuildAndTest
      Instructions: |
        Please review the infrastructure changes:
        1. Check the terraform plan output
        2. Verify all changes are expected
        3. Approve to deploy to production
      TimeoutInMinutes: 240  # 4 hours
      OnTimeoutBehaviour: reject  # Fail if not approved within 4 hours
```

### Conditional Approval (Only on Main Branch)

```yaml
jobs:
  - template: jobs/manual_verification.yml
    parameters:
      JobName: MainBranchApproval
      Condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
      Instructions: 'Main branch deployment requires approval'
```

### Auto-Resume on Timeout

```yaml
jobs:
  - template: jobs/manual_verification.yml
    parameters:
      JobName: QuickApproval
      Instructions: 'Quick check - auto-resumes after timeout'
      TimeoutInMinutes: 30
      OnTimeoutBehaviour: resume  # Automatically proceed if not rejected
```

---

## How It Works

### Execution Flow

1. Job starts and displays approval prompt in Azure DevOps UI
2. Approvers can view instructions and pipeline context
3. Job waits for approval decision or timeout
4. If approved: Job succeeds, pipeline continues
5. If rejected: Job fails, pipeline stops
6. If timeout: Action determined by `OnTimeoutBehaviour`

### Notifications

By default, this job doesn't send email notifications. To notify specific users or groups, integrate with other notification systems or use Azure DevOps notifications settings for the pipeline.

---

## Usage in Terraform Pipeline

This job is automatically used by the Terraform Pipeline when `RunMode` is `PlanVerifyApply`:

```yaml
extends:
  template: pipelines/terraform_pipeline.yml@AzDOPipelineTemplates
  parameters:
    EnvironmentConfigs:
      - Name: production
        Stage:
          DependsOn: Terraform_Build
          Condition: succeeded()
        TerraformDeploymentConfig:
          # ...
          RunMode: PlanVerifyApply
          VerificationMode: VerifyOnAny  # Triggers manual verification
```

In this context, the manual verification job appears automatically between the plan and apply jobs.

---

## Troubleshooting

### Approval Prompt Not Appearing

**Check**:
- ✓ Verify the job's condition is not preventing it from running
- ✓ Check that the job completed successfully up to the approval step
- ✓ Ensure you have the correct permissions to view approvals
- ✓ Verify the Azure DevOps Environment exists (if used in deployment context)

### Timeout Occurring Too Quickly

**Solution**: Increase `TimeoutInMinutes` to allow more time for review and approval:

```yaml
TimeoutInMinutes: 480  # 8 hours instead of 60 minutes (1 hour)
```

### Unable to Approve Due to Permissions

**Cause**: You may not have permission to approve in this environment.

**Solution**: Contact your Azure DevOps administrator to grant approval permissions for the specific environment.

---

## Best Practices

- **Clear instructions** – Provide context about what's being approved
- **Reasonable timeout** – Allow enough time for reviewers to respond
- **Consistent naming** – Use descriptive `JobName` values for clarity
- **Document gates** – Include approval gates in your deployment documentation
- **Track approvals** – Use Azure DevOps audit logs to track who approved what and when

---

## See Also

- [Terraform Gated Deployment Job](./terraform_gated_deployment.md) – Uses this job for infrastructure approvals
- [Manual Verification Flows](../pipelines/terraform_pipeline_manual_verification.md) – Learn about verification modes
- [Azure DevOps Manual Validation Task](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/manual-validation-v1)


