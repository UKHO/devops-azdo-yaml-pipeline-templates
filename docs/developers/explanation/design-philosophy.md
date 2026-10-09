# Design Philosophy

The repository was designed to be both **flexible** and **reusable**:

- Out-of-the-box pipelines for quick adoption (set menu).
- Modular, combinable job templates for custom scenarios (salad bar).
- PowerShell was adopted for scenarios that YAML expressions alone could not handle.
- Extensibility and clear documentation of platform limitations are priorities.

## Layered Templates

Templates are composed in layers by scope: **tasks → jobs → stages → pipelines**. A task wraps a single Azure DevOps task, jobs combine tasks, stages group jobs, and pipelines assemble stages into a complete run. This layering exists for three reasons:

- **Reusability** — smaller pieces can be recombined into new jobs, stages, and pipelines without duplication.
- **Testing at each level** — every layer has its own compile tests, so a change can be validated in isolation at the layer it affects rather than only through a full pipeline.
- **Safe substitution** — because each layer has a stable interface, an internal piece can be swapped out when it hits a limitation without disturbing the layers above it. For example, the terraform step was originally implemented as a dedicated task template, but that approach had limitations, so it was swapped for a `cmdline`-based implementation with no change to the jobs and pipelines that depend on it.

## Public vs. Internal

The reuse surface is deliberately narrow. **Only `pipelines/` and `jobs/` are public** — they are the only directories external consumers may reference, and they are the only ones under SemVer. Everything else (`tasks/`, `stages/`, `schemas/`, `utils/`, `scripts/`, `tools/`) is an **internal** building block used to compose the public templates; it is not for direct external use and carries no versioning guarantees. Keeping this surface small is what lets the internals evolve freely without breaking consumers.

## Behavioural Solutions, Not Building Blocks

We publish jobs and pipelines, not bare task templates, because they deliver complete behaviour. For example, `jobs/terraform_build.yml` performs every step needed to build Terraform, so consumers adopt an outcome rather than assembling low-level steps themselves — which is what many other online template libraries require. The public surface is intentionally the behavioural layer: consumers describe *what* they want (build Terraform, deploy with a verification gate), not *how* each step is wired.

## Fail Fast at Compile Time

Templates validate their inputs during YAML compilation, before any agent runs or any resource is touched. Schema templates in `schemas/` and inline guard expressions (a mapping whose value is `"Error"`, emitted under an `${{ if ... }}`) reject malformed input immediately with a descriptive message. A misconfigured pipeline fails the moment it is queued rather than part-way through execution, making failures cheap, fast, and unambiguous.

## Fully-Declared, Self-Documenting Parameters

Every parameter declares its `name`, `type`, `displayName`, and (where applicable) `default` and `values`. Required parameters deliberately omit a default so a missing value fails loudly instead of running with a silent fallback, and enum parameters constrain input with `values`. The declaration *is* the contract and the documentation, which is also what makes compile-time validation and the `displayName`-driven UI possible.

## Protect Template-Internal State

Variables a template defines for its own use are marked `readonly: true`. Azure DevOps variable precedence would otherwise let a consumer's variable of the same name silently override template internals; `readonly` closes that gap so a template's behaviour cannot be subverted from outside.

## Defensive, Safe Rendering

Templates degrade gracefully on edge-case input rather than emitting broken YAML. For example, `utils/concat_wrap_list.yml` renders an empty string for an empty list instead of a half-formed expression. The guiding rule: a template should either produce valid output or fail with a clear compile-time error — never produce something subtly wrong.

## Group Related Inputs Into Validated Objects

Conceptually related values are grouped into a single object parameter (for example `TerraformDeploymentConfig`) rather than a long flat list of loose parameters. Each object is validated by a dedicated schema template, keeping call sites readable while still enforcing structure and required fields.

## Flexible Execution Paths

A single template can select an execution strategy from its inputs instead of forcing consumers into separate templates. For example, `tasks/terraform.yml` runs a native script when no `ServiceConnection` is supplied and switches to `AzureCLI@2` for authenticated access when one is — one interface, the right behaviour chosen at compile time.

## What to Template

Not everything should become a template. Only abstract logic that genuinely benefits from reuse, validation, or a stable interface — templating trivial or one-off YAML adds indirection without payoff. (Some elements also cannot be templated at all, such as the root `trigger` and `pr` blocks.)

See [Architecture](../../../ARCHITECTURE.md) for the folder layout and invariants this philosophy produced, and [Double Wrapping](double-wrapping.md) for a worked example of a design mistake this philosophy ruled out.
