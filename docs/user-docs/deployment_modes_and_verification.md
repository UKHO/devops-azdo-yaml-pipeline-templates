# Deployment Modes and Verification Strategies

This guide explains the different deployment modes and verification strategies available in the Terraform pipeline/job templates. Understanding these modes is essential for implementing deployments that match your organizational requirements and risk tolerance.

## Overview

Templates support three core deployment modes, each with distinct behaviors for planning and applying infrastructure changes:

- **PlanOnly** — Preview changes without deployment
- **ApplyOnly** — Deploy without planning
- **PlanVerifyApply** — Plan, optionally verify, then apply with conditional approval

Each mode can be combined with verification strategies to control when manual approval is required.

---

## Deployment Modes

### PlanOnly Mode

**Use case:** Preview-only scenarios where changes are reviewed but not automatically deployed

**Possible uses:**

- Continuous integration pipelines that validate Terraform configurations
- Planning changes without approval gates
- CI pipelines that plan but don't deploy
- Change preview and estimation without execution

**Generated jobs:**

- `TerraformDeployPlan_<ArtifactName>` — Plan job only

**Configuration:**

```yaml
TerraformDeploymentConfig:
  RunMode: PlanOnly
  # No VerificationMode needed
```

**Output:**

- Plan output is displayed in pipeline logs
- No infrastructure changes are applied
- Plan can be reviewed for analysis and discussion

---

### ApplyOnly Mode

**Use case:** Rapid deployments to non-critical environments or follow-up deployments after planning

**Possible uses:**

- Rapid deployments to development environments
- Pre-planned infrastructure updates where planning was already completed in a previous pipeline run
- Second-stage pipelines that apply pre-planned changes
- Faster deployments when infrastructure changes are well-known

**Generated jobs:**

- `TerraformDeployApply_<ArtifactName>` — Apply job only

**Configuration:**

```yaml
TerraformDeploymentConfig:
  RunMode: ApplyOnly
  # No VerificationMode needed
```

**Considerations:**

- Infrastructure is deployed directly without a planning phase
- No opportunity to review changes before deployment
- Use only for non-critical environments or well-understood changes
- Verify your Terraform configuration separately before using ApplyOnly

---

### PlanVerifyApply Mode

**Use case:** Production deployments where changes must be reviewed and approved before application

**Possible uses:**

- Production deployments requiring approval
- Multi-stage deployments with verification gates
- Compliance-heavy environments requiring manual sign-off
- Pipelines where destructive changes must be audited

**Generated jobs:**

- `TerraformDeployPlan_<ArtifactName>` — Plan phase
- `ManualVerification_<ArtifactName>` — Verification gate (inserted conditionally)
- `TerraformDeployApply_<ArtifactName>` — Apply phase (conditional)

**Execution flow with verification needed:**

```
Build Artifact
     ↓
Terraform Plan (preview changes)
     ↓
Changes detected (verification required)
     ↓
Manual Verification Gate
     ↓
     ├─ Approved → Terraform Apply
     └─ Rejected → Stop (no changes applied)
```

**Execution flow with no verification needed:**

```
Build Artifact
     ↓
Terraform Plan (preview changes)
     ↓
Changes detected (no verification needed)
     ↓
Terraform Apply (auto-proceed)
```

**Configuration:**

```yaml
TerraformDeploymentConfig:
  RunMode: PlanVerifyApply
  VerificationMode: VerifyOnDestroy  # or VerifyOnAny, VerifyDisabled
```

**Key differences from other modes:**

- Changes are previewed before application
- Manual approval may be required (based on VerificationMode)
- Plan output is evaluated against verification strategy
- Provides highest level of control and auditability

---

## Verification Modes

Verification modes control when manual approval is required during PlanVerifyApply deployments. They allow you to tailor your approval process to the risk level of each change.

### VerifyOnDestroy

**When approval is required:** Only when the plan includes resource destruction

**Use case:** Conservative approach for production where resource deletion requires approval

**Behavior:**

- **Resource creation:** Proceeds without verification
- **Resource modification:** Proceeds without verification
- **Resource destruction:** Requires manual verification gate
- Applied as: `VerificationMode: VerifyOnDestroy` in `PlanVerifyApply` mode

**Example scenario:**

```
Terraform Plan detects:
  + aws_instance.web (create) → No verification required
  ~ aws_security_group.sg (modify) → No verification required
  - aws_rds_instance.db (destroy) → Manual verification REQUIRED
```

**Use in pipeline:**

```yaml
TerraformDeploymentConfig:
  RunMode: PlanVerifyApply
  VerificationMode: VerifyOnDestroy
```

---

### VerifyOnAny

**When approval is required:** For any infrastructure changes (creation, modification, or destruction)

**Use case:** Most cautious approach where all changes require human review

**Behavior:**

- **Resource creation:** Requires manual verification gate
- **Resource modification:** Requires manual verification gate
- **Resource destruction:** Requires manual verification gate
- Applied as: `VerificationMode: VerifyOnAny` in `PlanVerifyApply` mode

**Example scenario:**

```
Terraform Plan detects ANY changes (add, modify, or delete)
     ↓
Manual verification gate is inserted
     ↓
Approver reviews and votes
```

**Use in pipeline:**

```yaml
TerraformDeploymentConfig:
  RunMode: PlanVerifyApply
  VerificationMode: VerifyOnAny
```

**Best practices:**

- Use for production environments with strict change control
- Combine with detailed approval instructions
- Consider performance impact of approval delays

---

### VerifyDisabled

**When approval is required:** Never (manual verification gate is skipped)

**Use case:** Automated deployments where changes are fully validated by CI/CD pipeline

**⚠️ Warning:**

- This verification mode bypasses manual approval entirely
- Use only after thorough automated testing and validation
- Not recommended for production environments
- Consider using ApplyOnly mode instead for simpler deployments

**Behavior:**

- All Terraform changes proceed automatically
- No manual verification gate is inserted
- Changes apply immediately after planning
- Applied as: `VerificationMode: VerifyDisabled` in `PlanVerifyApply` mode

**Example scenario:**

```
Terraform Plan detects changes
     ↓
No verification gate (VerifyDisabled)
     ↓
Terraform Apply proceeds immediately
```

**Use in pipeline:**

```yaml
TerraformDeploymentConfig:
  RunMode: PlanVerifyApply
  VerificationMode: VerifyDisabled
```

---

## Related Documentation

- [**Terraform Gated Deployment Job**](./jobs/terraform_gated_deployment_job.md) — Orchestrates PlanVerifyApply workflows
- [**Terraform Deploy Job**](./jobs/terraform_deploy_job.md) — Single-phase plan or apply operations
- [**Terraform Pipeline**](./pipelines/terraform_pipeline.md) — Complete multi-environment deployment
- [**Manual Verification Job**](./jobs/manual_verification_job.md) — Manual approval gate implementation


