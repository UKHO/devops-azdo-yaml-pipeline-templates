# ManualVerificationConfig

A reusable configuration object that can be embedded inside other configuration objects (e.g.
[`TerraformDestroyConfig`](./terraform_destroy_config.md)) to control the behaviour of an automatically-inserted
[Manual Verification job](../../user-docs/jobs/manual_verification.md).

If this object is provided at all, `TimeoutInMinutes` is **required** - there is little point using the object
otherwise. `Instructions` and `OnTimeoutBehaviour` remain optional and fall back to the consuming job template's
own defaults when omitted.

## Definition

```yaml
ManualVerificationConfig:
  TimeoutInMinutes: number       # REQUIRED (once this object is provided) - 1-43200
  Instructions: string           # OPTIONAL
  OnTimeoutBehaviour: string     # OPTIONAL ('reject' | 'resume')
```

## Required Properties

### TimeoutInMinutes

**Type:** `number`

**Allowed Range:** `1` - `43200` (30 days)

**Description:** How long to wait for manual approval before applying `OnTimeoutBehaviour`. Required whenever
`ManualVerificationConfig` is supplied.

## Optional Properties

### Instructions

**Type:** `string`

**Description:** Instructions displayed to approvers explaining what they're approving. When omitted, the
consuming job template supplies its own default instructions text.

### OnTimeoutBehaviour

**Type:** `string`

**Allowed Values:** `'reject'` | `'resume'`

**Description:** Action to take if the manual verification is not actioned within `TimeoutInMinutes`.

- `'reject'` - The job fails, halting the pipeline (default behaviour).
- `'resume'` - The job automatically succeeds as if approved, and the pipeline continues.

## Notes for Template Authors

- Validation of this object is owned by [`jobs/manual_verification.yml`](../../../jobs/manual_verification.yml)
  (via [`schemas/manual_verification_config.yml`](../../../schemas/manual_verification_config.yml)), since that is
  the template that actually consumes the fields.
- Orchestrator/gated job templates (e.g. `jobs/terraform_gated_destroy.yml`) that embed a manual verification step
  act only as a "passer" of this object - they may enhance it (for example, injecting their own default
  `Instructions` text when the consumer hasn't supplied one) before forwarding it to `jobs/manual_verification.yml`,
  but they do not perform validation themselves.

## Example: Automated / Unattended Testing

For unattended pipeline tests where no human is available to approve, a short timeout combined with `resume`
lets the gate trigger, time out, and continue automatically - proving the gate itself functions correctly without
requiring human interaction:

```yaml
TerraformDestroyConfig:
  AzDOEnvironmentName: test-environment
  RunMode: PlanVerifyDestroy
  ManualVerificationConfig:
    TimeoutInMinutes: 1
    OnTimeoutBehaviour: resume
```

## Related Tests

- [`schemas/manual_verification_config.CompileTests.ps1`](../../../schemas/manual_verification_config.CompileTests.ps1)
- [`jobs/manual_verification.CompileTests.ps1`](../../../jobs/manual_verification.CompileTests.ps1)
- [`jobs/terraform_gated_destroy.CompileTests.ps1`](../../../jobs/terraform_gated_destroy.CompileTests.ps1)

## See Also

- [Manual Verification Job](../../user-docs/jobs/manual_verification.md)
- [Terraform Gated Destroy Job](../../user-docs/jobs/terraform_gated_destroy.md)
- [Terraform Destroy Config Definition](./terraform_destroy_config.md)
