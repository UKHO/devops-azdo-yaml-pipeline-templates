# Infrastructure Pipeline Manual Verification

This template allows a pipeline to deploy resources via Terraform with an optional manual verification step, aka gate, for any resources planned to be changed. This functionality is controlled by two parameters: a boolean `RunPlanOnly` flag, and a `VerificationMode` parameter. When `RunPlanOnly` is `true`, the template runs only the Terraform `plan` and does not trigger the gate or the `apply` stage. When `RunPlanOnly` is `false`, the `VerificationMode` parameter determines how the gate behaves and has three settings: `VerifyDisabled`, don't trigger the gate at all; `VerifyOnDestroy`, trigger the gate only if the changes are destructive; and `VerifyOnAny`, trigger the gate for adds, changes, and deletions. If the Terraform `plan` indicates that any resources will be changed, then `VerificationMode` will be checked and the appropriate verification taken; if no resources will be changed then the `apply` will not be called. If the gate is triggered, then authorised users will need to approve in Azure DevOps in order to move on to the `apply` step. The gate will fail the pipeline if either rejected or times out.

The template is broken into three jobs:

- plan job
- gate (manual verification) job
- apply job

The flow works as follows

```mermaid
---
title: Gate Flow
---
flowchart TD
    pipeline([Pipeline])
    plan[[Plan Job]]
    changes{Changes<br>Detected}
    planOnly{Plan<br>Only}
    mode{Manual<br>Verification<br>Mode}
    gate{Approval<br>Gate}
    destroy{Are<br>changes<br>destructive?}
    apply[[Apply Job]]
    succeeded([Template Succeeded])
    failed([Template Failed])

    pipeline-->plan
    plan-->planOnly
    planOnly--Yes-->succeeded
    planOnly--No-->changes
    changes--No changes detected-->succeeded
    changes--Changes detected-->mode
    mode--VerifyDisabled-->apply
    mode--VerifyOnAny-->gate
    mode--VerifyOnDestroy-->destroy
    destroy--Yes-->gate
    destroy--No-->apply
    gate--Plan approved-->apply
    gate--Plan not approved or timeout-->failed
    apply-->succeeded
```
