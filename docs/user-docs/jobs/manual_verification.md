# Manual Verification Job

A reusable job template that pauses a pipeline for manual approval by wrapping the Azure DevOps `ManualValidation@1` task with configurable approvers, instructions, and timeout behaviour.

```yaml
jobs:
  - template: jobs/manual_verification.yml
    parameters:
      # No parameters are required - every value below is shown at its default. Uncomment and change a value to override it.

      # JobName: 'ManualVerification'       # Name of the job for identification in pipeline logs.
      # Instructions: ''                    # Text displayed to approvers explaining what they are approving.
      # TimeoutInMinutes: 60                # Minutes to wait for a decision (max 43200 = 30 days).
      # OnTimeoutBehaviour: reject          # Action on timeout: 'reject' (fail) or 'resume' (auto-approve).
      # Condition: succeeded()              # Condition controlling whether this job runs.
      # DependsOn:                          # (list) Jobs this job depends on. Defaults to an empty list.
```

---

## How It Works

1. Job starts and displays the approval prompt in the Azure DevOps UI.
2. Approvers view the instructions and pipeline context.
3. Job waits for an approval decision or timeout.
4. If approved: job succeeds and the pipeline continues.
5. If rejected: job fails and the pipeline stops.
6. If timeout: the outcome is determined by `OnTimeoutBehaviour` (`reject` fails, `resume` proceeds).

By default no email notifications are sent. Use the Azure DevOps pipeline notification settings to alert approvers.

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
      TimeoutInMinutes: 240       # 4 hours
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

**Live example**: [`tests/jobs/manual_verification/resume_test.yml`](../../../tests/jobs/manual_verification/resume_test.yml) (also see [`double_resume_test.yml`](../../../tests/jobs/manual_verification/double_resume_test.yml) for two gates in one pipeline)

---

## See Also

- [Terraform Gated Deployment Job](./terraform_gated_deployment.md) – Uses this job for infrastructure approvals
- [Manual Verification Flows](../pipelines/terraform_pipeline_manual_verification.md) – Learn about verification modes
- [Azure DevOps Manual Validation Task](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/reference/manual-validation-v1)
