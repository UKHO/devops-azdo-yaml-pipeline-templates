# Manual Verification Job

A job template that creates a manual pause point in your pipeline requiring human approval to proceed. This job provides a built-in delay mechanism and customizable approval instructions, making it ideal for deployment gates, change approvals, or manual validation checkpoints.

## Overview

The Manual Verification Job:

- Pauses pipeline execution and waits for manual approval within a configurable timeout
- Displays custom instructions to approvers explaining what requires verification
- Supports approval timeout behavior (reject the pipeline or allow it to continue on timeout)
- Can be conditionally included based on pipeline logic
- Integrates seamlessly with deployment workflows and automated gates
- Runs on the server (no agent required), making it lightweight and reliable

## Important Notices

### Approvers and Permissions

Manual verification gates require Azure DevOps Environments with configured approvers:

- The job must be tied to an Azure DevOps Environment
- Approvers must have "Manage deployment approvals" permission on the environment
- Unless using a server job (which doesn't require an environment), the environment must exist

For this job template, approvers are typically configured at the pipeline level where this job is used, not on the job template itself.

### Timeout Behavior

The timeout determines how long the pipeline waits for approval:

- **`reject` behavior** — Pipeline fails if timeout is reached (deployment is rejected)
- **`resume` behavior** — Pipeline continues if timeout is reached (useful for optional approvals)

Choose `reject` for mandatory approvals and `resume` for optional checkpoints.

### Use in Automated Gates

This job can be conditionally included in automated deployment gates (e.g., only when infrastructure destruction is detected). See the Terraform Gated Deployment job for an example.

## Basic Usage

### Simple Approval Gate

```yaml
- template: jobs/manual_verification.yml@AzDOPipelineTemplates
  parameters:
    JobName: ApproveDeployment
    Instructions: 'Please review the deployment plan and approve to proceed.'
```

### Approval with Custom Timeout

```yaml
- template: jobs/manual_verification.yml@AzDOPipelineTemplates
  parameters:
    JobName: ReleaseApproval
    TimeoutInMinutes: 120
    Instructions: 'Changes require architectural review. Approve if changes align with our infrastructure standards.'
```

### Conditional Approval (Resume on Timeout)

```yaml
- template: jobs/manual_verification.yml@AzDOPipelineTemplates
  parameters:
    JobName: OptionalSignOff
    TimeoutInMinutes: 30
    OnTimeoutBehaviour: resume
    Instructions: 'Optional: Stakeholder sign-off requested. Pipeline continues automatically if no response.'
```

### Approval Gate with Dependencies

```yaml
- template: jobs/manual_verification.yml@AzDOPipelineTemplates
  parameters:
    JobName: PreProductionApproval
    DependsOn:
      - 'TerraformDeployPlan_Prod'
      - 'SecurityScan'
    Condition: and(succeeded('TerraformDeployPlan_Prod'), succeeded('SecurityScan'))
    Instructions: 'Review security scan results and terraform plan. Approve to proceed with production deployment.'
    TimeoutInMinutes: 60
```

## Full Parameter Table

| Parameter Name       | Type   | Required | Default                | Description                                                                                                                                                           |
|----------------------|--------|----------|------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `JobName`            | string | No       | `'ManualVerification'` | Unique name for the job within the pipeline. Must be distinct from other jobs if multiple verification gates are used.                                                |
| `DependsOn`          | object | No       | `[]`                   | List of job names this verification depends on (e.g., `['TerraformPlan', 'SecurityScan']`). Job waits for dependencies to complete before displaying approval prompt. |
| `Condition`          | string | No       | `succeeded()`          | Condition expression controlling whether this job runs (e.g., `eq(variables['Build.SourceBranch'], 'refs/heads/main')`).                                              |
| `TimeoutInMinutes`   | number | No       | `60`                   | Time to wait for approval (in minutes). Must be a positive number. If exceeded, behavior is determined by `OnTimeoutBehaviour`.                                       |
| `OnTimeoutBehaviour` | string | No       | `'reject'`             | Action when timeout is reached: `'reject'` (fail the pipeline) or `'resume'` (continue the pipeline).                                                                 |
| `Instructions`       | string | No       | `''`                   | Custom instructions displayed to approvers. Explain what requires approval and any context needed for decision-making.                                                |

## Advanced Usage

### Multi-Stage Verification Pipeline

Use multiple verification gates for different approval stages:

```yaml
stages:
  - stage: Build
    jobs:
      - template: jobs/terraform_build.yml@AzDOPipelineTemplates
        parameters:
          RelativePathToTerraformFiles: 'infra'

  - stage: SecurityReview
    dependsOn: Build
    jobs:
      - template: jobs/manual_verification.yml@AzDOPipelineTemplates
        parameters:
          JobName: SecurityApproval
          DependsOn:
            - 'TerraformBuild_Artifact'
          Instructions: |
            Security team: Please verify the infrastructure changes.

            Changes include:
            - Network security group modifications
            - Database access rule updates
            - Storage account permissions

            Review the terraform plan artifact and approve if changes are compliant with our security policies.
          TimeoutInMinutes: 240

  - stage: ArchitectureReview
    dependsOn: SecurityReview
    jobs:
      - template: jobs/manual_verification.yml@AzDOPipelineTemplates
        parameters:
          JobName: ArchitectureApproval
          Instructions: 'Architecture team: Verify infrastructure design aligns with our standards and business requirements.'
          TimeoutInMinutes: 240

  - stage: Deploy
    dependsOn: ArchitectureReview
    jobs:
      - template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
        parameters:
          TerraformDeployMode: Apply
          # ... deployment configuration ...
```

### Conditional Verification Based on Change Scope

```yaml
- template: jobs/terraform_gated_deployment.yml@AzDOPipelineTemplates
  parameters:
    EnvironmentName: production
    TerraformDeploymentConfig:
      AzDOEnvironmentName: prod-environment
      AzureServiceConnection: Pipeline-prod
      RunMode: PlanVerifyApply
      VerificationMode: VerifyOnDestroy
      # Verification gate automatically inserts when infrastructure destruction is detected
      # ... rest of configuration ...
```

In this example, the `terraform_gated_deployment` template uses this job internally to create a verification gate when destructive changes are detected.

### Optional Approval for Non-Critical Changes

```yaml
stages:
  - stage: DeployDev
    jobs:
      - template: jobs/manual_verification.yml@AzDOPipelineTemplates
        parameters:
          JobName: DevApprovalOptional
          OnTimeoutBehaviour: resume
          TimeoutInMinutes: 30
          Instructions: 'Optional: Dev deployment in progress. Respond to be notified, or pipeline continues automatically.'

      - template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
        parameters:
          DependsOn:
            - DevApprovalOptional
          TerraformDeployMode: Apply
          # ... deployment configuration ...
```

## Job Execution Details

### Job Configuration

- **Pool:** `server` — Runs as a server job (lightweight, no agent required)
- **Display Name:** `Manual Verification` — Shown in pipeline UI
- **Step 1:** Delay step (optional pause before showing approval prompt)
- **Step 2:** Manual validation step (approval prompt with custom instructions)

### Approval Mechanism

When the job runs:

1. Pipeline displays the job name and instructions in Azure DevOps UI
2. Approvers receive notification (if configured)
3. Approvers can:
  - **Approve** — Pipeline continues to next stage
  - **Reject** — Pipeline stops with failure status
  - **Timeout** — Behavior depends on `OnTimeoutBehaviour` setting

## Common Patterns

### Production vs. Development Gating

```yaml
stages:
  - stage: DeployDev
    jobs:
      - template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
        parameters:
          TerraformDeployMode: Apply
          # No approval gate for development
          # ... configuration ...

  - stage: DeployProd
    jobs:
      - template: jobs/manual_verification.yml@AzDOPipelineTemplates
        parameters:
          JobName: ProdApproval
          TimeoutInMinutes: 240
          Instructions: 'Production approval required.'

      - template: jobs/terraform_deploy.yml@AzDOPipelineTemplates
        parameters:
          DependsOn:
            - ProdApproval
          TerraformDeployMode: Apply
          # ... configuration ...
```

## Related Templates

- [**terraform_deploy_job.md**](terraform_deploy_job.md) — Infrastructure deployment job
- [**terraform_gated_deployment_job.md**](terraform_gated_deployment_job.md) — Uses this job for conditional approval gates
- [**Terraform Pipeline**](../pipelines/terraform_pipeline.md) — Complete infrastructure deployment with approval gates

