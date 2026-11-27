# Implementation Plan: `ApplyEvenIfNoChanges`

> Working document. This is the source of truth for this piece of work; update the status
> boxes as each step completes. Lives in `temp/` and is **not** to be committed.

- **Branch:** `feature/tf-tmpl-applyevenifnochanges` (on `origin/main` @ `50ba523`). Pushed with upstream set after Commit 1.
  (Supersedes `feature/terraform-template-parameter-applyifnochanges`, which still points at the old `d93c55f`.)
- **Changelog section:** `[Unreleased]` → `### Added`. Agreed as a **MINOR** bump (new optional, default-preserving parameter on a public `jobs/` template, per `docs/developers/reference/versioning-policy.md`) → next release `0.4.0`.

---

## 1. Problem

`jobs/terraform_gated_deployment.yml` skips the Apply job in `PlanVerifyApply` mode when the plan
reports no changes (`ChangesNeedApplying == 'false'`). Consumers who:

- chain later jobs off the Apply job succeeding, and/or
- rely on `OutputVariables`, which are **only** exported by the Apply job (`terraform output` after `terraform apply`)

get a skipped job and no output variables. A plan cannot produce the outputs, so consumer-side
condition workarounds do not solve it.

## 2. Solution

Add an optional boolean `ApplyEvenIfNoChanges` to `TerraformDeploymentConfig`.

- Default / absent = `false` → existing behaviour, compiled YAML **identical** to today (non-breaking).
- `true` → Apply job runs even when the plan has no changes.
- **Never bypasses manual verification.** Apply still only runs if manual verification is approved,
  or was not required (no changes / `VerifyDisabled` / `VerifyOnDestroy` without destroys).

### Design decisions (agreed)

| # | Decision |
|---|----------|
| D1 | Field name `ApplyEvenIfNoChanges`, boolean, optional, default `false`. |
| D2 | `true` only valid with `RunMode: PlanVerifyApply`. `true` + `PlanOnly`/`ApplyOnly` → schema error. |
| D3 | `false` allowed with any RunMode (no-op). |
| D4 | Non-boolean value → schema error (same `notIn(x, true, false)` pattern as `RunAsPreJob` in `schemas/config_sources.yml`). |
| D5 | Missing/invalid RunMode reports only the RunMode error (conflict check uses `in(RunMode, 'PlanOnly', 'ApplyOnly')`, not `ne(RunMode, 'PlanVerifyApply')`). |
| D6 | Validation lives in `schemas/terraform_gated_deployment_config.yml` only (gated-only field). Leaf `terraform_deploy.yml` untouched. |
| D7 | `terraform_gated_destroy` is **out of scope**: it has no changes-check; destroy always runs after verification succeeds, and destroy config has no `OutputVariables`. Mention in docs. |

### Why it works at runtime

- `scripts/terraform/terraform_changes_check.ps1` always emits `ChangesNeedManualVerification=false`
  and `ChangesNeedApplying=false` when there are no changes.
- The Apply job runs `terraform apply -auto-approve` itself (not a saved plan file), so a no-change
  apply succeeds and the `TerraformExportOutputsVariables` step publishes outputs.

### Template change (Apply job condition, `PlanVerifyApply` only)

Current:

```yaml
or(
  succeeded('ManualVerification_X'),
  and(
    succeeded('TerraformDeployPlan_X'),
    eq(...ChangesNeedApplying, 'true'),
    eq(...ChangesNeedManualVerification, 'false')
  )
)
```

With `ApplyEvenIfNoChanges: true` — compile-time removal of the `ChangesNeedApplying` clause only:

```yaml
or(
  succeeded('ManualVerification_X'),
  and(
    succeeded('TerraformDeployPlan_X'),
    eq(...ChangesNeedManualVerification, 'false')
  )
)
```

Behaviour matrix (flag `true`):

| Plan result | Verification needed | MV outcome | Apply |
|---|---|---|---|
| No changes | no | skipped | **runs** (new) |
| Changes | no (VerifyDisabled / VerifyOnDestroy no destroys) | skipped | runs (unchanged) |
| Changes | yes | approved / resume-on-timeout | runs (unchanged) |
| Changes | yes | rejected / reject-on-timeout | **skipped** (unchanged — gate respected) |
| Plan failed | – | – | skipped (unchanged) |

---

## 3. Work breakdown & commits

Each commit is **presented to the maintainer for review before committing**.

### Commit 0 — Developer docs: E2E tests must finish green
`docs(developers): document that e2e test pipelines must finish green for GitHub Status Checks`

- [x] `docs/developers/how-to/test-a-template.md` — new "End-to-end test pipelines must finish green" section
- [x] `.github/copilot-instructions.md` — Key Principles bullet linking to it
- [x] Committed by maintainer as `5de778c` "Doc update, instructions about E2E tests" (on this branch;
      also includes maintainer's own `docs/developers/reference/versioning-policy.md` changes)

### ~~Commit 0b — Test framework: survive az auto-upgrade prompt~~ (DROPPED)
`fix(tests): stop az auto-upgrade prompt breaking compile test pre-flight`

- [x] `tests/framework/Core.ps1` — process-scoped `${env:AZURE_AUTO-UPGRADE_ENABLE} = 'no'`
- [x] `tests/framework/Core.PreFlightValidation.ps1` — `Test-AzAuthentication` uses `$LASTEXITCODE`, not stderr
- [x] `tests/framework/Core.Authentication.ps1` — only `ConvertFrom-Json` when `az account show` succeeded
- [x] **Dropped by maintainer** — not part of this work. Local workaround if the prompt reappears:
      `az config set auto-upgrade.enable=no` (or `auto-upgrade.prompt=no`).

### Commit 1 — Schema
`feat(schema): add ApplyEvenIfNoChanges validation to terraform_gated_deployment_config`

- [x] `schemas/terraform_gated_deployment_config.yml` — boolean check + PlanVerifyApply-only check; header comment updated
- [x] `schemas/terraform_gated_deployment_config.CompileTests.ps1`
  - Valid: `true`+PlanVerifyApply, `false`+PlanVerifyApply, `false`+PlanOnly, `false`+ApplyOnly
  - Invalid: `true`+PlanOnly, `true`+ApplyOnly, `"yes"`
- [x] Committed by maintainer as `67df4bb` "Add ApplyEvenIfNoChanges to TerraformDeploymentConfig schema"

### Commit 2 — Job template
`feat(jobs): support ApplyEvenIfNoChanges in terraform_gated_deployment`

- [x] `jobs/terraform_gated_deployment.yml` — **revised per maintainer review**: single `Condition`; the
      `ChangesNeedApplying == 'true'` check is wrapped in `or(..., eq('${{ ApplyEvenIfNoChanges }}', 'true'))`.
      Compile-time rendering: absent → `eq('', 'true')`, `false` → `eq('False', 'true')`, `true` → `eq('True', 'true')`
      (runtime `eq` is case-insensitive). Default compiled YAML is no longer byte-identical but is runtime-equivalent.
      (First draft used a nested `${{ if }}`/`${{ else }}` with two full conditions — rejected as duplicative.)
      (Considered `eq('${{ eq(flag, true) }}', 'True')` to always render True/False — declined by maintainer; keep simple form.)
- [x] `jobs/terraform_gated_deployment.CompileTests.ps1`
  - Valid: flag absent → `or(*ChangesNeedApplying'?, 'true'),*eq('', 'true')*)`
  - Valid: flag `false` → `... eq('false', 'true') ...` (`-like` is case-insensitive)
  - Valid: flag `true` → `... eq('true', 'true') ...` + `ChangesNeedManualVerification == 'false'` + MV job,
    `succeeded('ManualVerification_...')`, dependsOn still present
  - Valid: flag `true` with VerifyOnDestroy / VerifyDisabled / custom artifact name; `false` with PlanOnly / ApplyOnly
  - Invalid: `true`+PlanOnly, `true`+ApplyOnly, `"yes"`
  - Note: `-like` treats `[ ]` as wildcards, so `?` stands in for them
- [x] Committed by maintainer as `ea3843b` "Add ApplyEvenIfNoChanges to terraform_gated_deployment job"

### Commit 3 — E2E pipeline tests
`test(jobs): add ApplyEvenIfNoChanges e2e tests for terraform_gated_deployment`

Common shape (all three files): deployment one = `ApplyOnly` (always applies → state guaranteed current,
no reliance on state from a previous run); deployment two = `PlanVerifyApply` + `VerifyOnAny` (1-min
`resume` timeout as a safety net) against the same state key, depending on Apply one; assertion job
(`condition: not(canceled())`) reads `dependencies.<job>.result` / outputs via `$[ ]` job variables and
`exit 1`s only on a genuine regression. Every assertion also checks Plan `Succeeded`,
`ChangesNeedApplying == False` (proves the no-changes scenario was really exercised) and
ManualVerification `Skipped`.

- [x] `plan_verify_apply_apply_even_if_no_changes_test.yml` (positive) — asserts Apply `Succeeded`
      and `random_number` / `random_string` outputs non-empty
- [x] `plan_verify_apply_no_changes_skips_apply_test.yml` (negative, flag absent) — asserts Apply `Skipped`
- [x] `plan_verify_apply_apply_even_if_no_changes_false_test.yml` (negative, flag `false`) — asserts Apply `Skipped`
- [ ] Maintainer review → commit
- [ ] Each new file registered as an Azure DevOps pipeline (maintainer) before e2e run

<details><summary>Original design notes</summary>

- [ ] `plan_verify_apply_apply_even_if_no_changes_test.yml` (positive)
  1. Build artifact one → gated deploy one (`PlanVerifyApply`, `VerifyDisabled`) to put state in place.
  2. Build artifact two → gated deploy two, `DependsOn` deploy one's Apply, same state key,
     `ApplyEvenIfNoChanges: true` → plan has no changes, Apply must still run.
  3. Assertion job (`condition: always()`, depends on deploy two's Plan + Apply) maps
     `$[ dependencies.TerraformDeployApply_<two>.result ]` and the `random_number` / `random_string`
     outputs into job variables; script fails unless result is `Succeeded` **and** outputs are non-empty.
- [ ] `plan_verify_apply_no_changes_skips_apply_test.yml` (negative / regression guard for default behaviour)
  1. Same as above, but deploy two has `ApplyEvenIfNoChanges` **absent**.
  2. Assertion job (`condition: always()`) maps `$[ dependencies.TerraformDeployApply_<two>.result ]`;
     script fails unless result is `Skipped`, and also asserts the Plan job `Succeeded`
     (so a broken plan can't masquerade as a pass).
- [ ] (Optional, if cheap) `..._explicit_false_...` variant — same as negative test with `ApplyEvenIfNoChanges: false`.
- [ ] Assertion jobs must themselves fail the pipeline on mismatch (script `exit 1`), since a
      condition-only assertion would just be skipped and look green.
- [ ] **E2E rule (GitHub Status Checks):** no job may fail when the template behaves correctly.
      Both tests above finish green on correct behaviour: the negative test's Apply is *skipped*
      (skipped ≠ failed), and assertion jobs only `exit 1` on a genuine regression.
      Rule documented in `docs/developers/how-to/test-a-template.md` (see Commit 0).
- [ ] Compile-validated automatically by `tests/jobs/jobs.CompileTests.ps1` (`Run-DirectoryCompileTests`)

</details>
- [ ] Maintainer review → commit

### Commit 4 — Documentation
`docs: document ApplyEvenIfNoChanges for TerraformDeploymentConfig`

- [ ] `docs/definition_docs/terraform_pipeline/terraform_job_config.md`
  - Definition block: add `ApplyEvenIfNoChanges: boolean # OPTIONAL - gated job only (only valid when RunMode is PlanVerifyApply)`
  - New "Gated-only fields" section entry: purpose (downstream deps + OutputVariables), default, validation rules, manual verification never bypassed, note on gated destroy (D7)
  - Related Tests: link new e2e test
- [ ] `docs/user-docs/jobs/terraform_gated_deployment.md` — parameter/field table, behaviour description, example
- [ ] `docs/definition_docs/terraform_pipeline/environment_config.md` — check whether field list/example needs it; add related test link
- [ ] `docs/user-docs/pipelines/terraform_pipeline_parameters_in_detail.md` / `terraform_pipeline_manual_verification.md` — check for RunMode/skip-apply wording to update
- [ ] Maintainer review → commit

### Commit 5 — Changelog
`docs(changelog): add ApplyEvenIfNoChanges to Unreleased`

- [ ] `CHANGELOG.md` → `[Unreleased]` → `### Added` entry (non-breaking, opt-in, default false; MINOR)
- [ ] Maintainer review → commit

---

## 4. Compile test execution (server-side, bottom-up)

Templates are compiled by Azure DevOps against what is **on the server** for this branch, so each
layer must be pushed before testing the layer that consumes it.

**Process (amended by maintainer):** after each layer's targeted compile test passes, run the full
suite from the repo root with `.\Run-AllCompileTests.ps1` (discovers and runs every
`*.CompileTests.ps1`; exits non-zero on any failure) to be certain nothing else regressed. A layer is
only "done" when **both** the targeted test and `Run-AllCompileTests.ps1` are green.

- [x] Push branch after Commit 1 (`git push -u origin feature/tf-tmpl-applyevenifnochanges`)
- [x] Run `schemas/terraform_gated_deployment_config.CompileTests.ps1` → all pass
- [x] Run `.\Run-AllCompileTests.ps1` → all pass
- [ ] Push after Commit 2
- [ ] Run `jobs/terraform_gated_deployment.CompileTests.ps1` → all pass
- [ ] Run `.\Run-AllCompileTests.ps1` → all pass (covers `terraform_deploy` schema/job regression)
- [ ] Push after Commit 3
- [ ] Run `tests/jobs/jobs.CompileTests.ps1` → all pass (includes new e2e files)
- [ ] Run `.\Run-AllCompileTests.ps1` → all pass (covers `tests/pipelines/pipelines.CompileTests.ps1`)
- [ ] After Commits 4 & 5 (docs/changelog only): `.\Run-AllCompileTests.ps1` once more before the review gate

## 5. Gates

- [ ] **STOP** — all compile tests green → maintainer full review
- [ ] E2E pipeline(s) deployed and run in Azure DevOps (maintainer-approved)
- [ ] PR raised

## 6. Resolved questions

- Version bump: **MINOR** (→ `0.4.0`), entry kept under `[Unreleased]` until release.
- Negative e2e test: **yes** — "the more tests the better".
- E2E green rule wording: **confirmed** — assertion jobs failing on a genuine regression is acceptable.

## Commit 3 rework (review feedback)
- Seed / Verify / Cleanup stages, one default TerraformArtifact (no artifact name variables)
- resource_group_terraform (added resource_group_name/location outputs), so a second plan has genuinely no changes
- Cleanup stage runs terraform_destroy DestroyOnly with not(canceled())
- Assertions use $(Var) directly, no env block
- jobs compile tests 42/42 green; awaiting user review


## Commit 4 (docs) - drafted, awaiting review
- terraform_job_config.md: definition line, ApplyEvenIfNoChanges section, related tests
- user-docs/jobs/terraform_gated_deployment.md: skeleton, table, no-changes note, example section
- user-docs/pipelines/terraform_pipeline.md: troubleshooting pointer


## Commit 5 (CHANGELOG + README upgrade row) - drafted, awaiting review
- Full Run-AllCompileTests: 19/19 files green
- NEXT: STOP for full user review, then E2E pipeline runs and PR

