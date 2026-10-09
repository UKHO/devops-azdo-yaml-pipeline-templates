# Architecture

This is the codemap for this repository: what lives where, and the invariants that rarely change. It is not a place for rationale (see `docs/developers/explanation/`) or fast-changing detail (see `docs/developers/reference/`). Expect this file to be reviewed a couple of times a year, not on every change.

## Folder Layout

| Folder | Purpose |
| --- | --- |
| `tasks/` | Templates wrapping individual Azure DevOps tasks. Stable interfaces, defaults, clear parameter names. |
| `jobs/` | Self-contained, reusable job-level templates. Includes parameter validation and may use schemas for complex objects. |
| `stages/` | Stage templates that group jobs for specific pipeline goals (e.g., environments or milestones). |
| `pipelines/` | Entry-point templates that assemble stages into complete pipelines. |
| `utils/` | Shared YAML snippets that support other templates. |
| `schemas/` | Validation templates for complex object parameters passed through pipelines. |
| `scripts/` | PowerShell scripts invoked **by templates at pipeline runtime**. These ship to consumers as part of the templates. |
| `tools/` | PowerShell scripts invoked **by developers of this repository**, for repository maintenance and automation. Never run inside a consumer's pipeline. |
| `tests/` | The PowerShell compile/test framework and test fixtures used to validate templates before merge. |
| `examples/` | Standalone illustrative pipelines/snippets that are not part of the template library itself. |
| `cicd/` | Terraform that provisions this repository's own Azure DevOps/GitHub CI/CD resources. Not consumed by template users. |
| `docs/` | All contributor and consumer documentation. |

## Placement Rules

- **Scripts consumed by templates at runtime** go in `scripts/`.
- **Scripts for maintaining this repository** go in `tools/`.
- **Templates** go in the folder matching their level: `tasks/`, `jobs/`, `stages/`, or `pipelines/`.
- **Schemas** go in `schemas/`.
- For templates that produce a list (e.g. a sequence of jobs), use a descriptive suffix such as `_job_list` in the filename.
- Do not create new top-level folders without team discussion.

## Public (External) vs. Internal

This is the most important boundary in the repository. Treat it as an invariant.

- **Public / external** — Only `pipelines/` and `jobs/` are the reuse surface. These are the *only* directories external consumers may reference, and they carry SemVer compatibility guarantees (see [Versioning Policy](docs/developers/reference/versioning-policy.md)).
- **Internal** — `tasks/`, `stages/`, `schemas/`, `utils/`, `scripts/`, and `tools/` are private building blocks consumed only by templates inside this repo. They are **not** reusable by external pipelines, must not be referenced directly from a consumer, and carry **no** versioning guarantees — they may change at any time, provided no public template's parameters, outputs, or documented behaviour change as a result.

| Directory | Audience | Versioned (SemVer) |
| --- | --- | --- |
| `pipelines/`, `jobs/` | External consumers | Yes |
| `tasks/`, `stages/`, `schemas/`, `utils/`, `scripts/`, `tools/` | Internal only | No |

## Set Menu vs. Salad Bar

The repository follows a "set-menu with salad bar" model: **set-menu** = `pipelines/` (complete, ready-to-use pipelines) and **salad bar** = `jobs/` (self-contained templates teams combine). `tasks/`, `stages/`, and `utils/` are internal building blocks used to compose them. See [Design Philosophy](docs/developers/explanation/design-philosophy.md) for the rationale.

## What Does Not Need to Be a Template

- Root pipeline elements (`trigger`, `pr`) cannot be templated.

## Documentation Location by Folder

| Folder | Documentation lives in |
| --- | --- |
| `tasks/`, `utils/` | In-file YAML comment block only |
| `jobs/`, `stages/` | In-file comment block, plus external docs in `docs/` where the template is complex enough to need one |
| `pipelines/` | In-file comment block, plus user-facing docs in `docs/user-docs/` |
| `schemas/` | Brief in-file comment block, plus `docs/definition_docs/` for the validated object |

## Invariants

These rarely change. If one of them needs to change, it needs an ADR (`docs/developers/adr/`), not just a PR:

- **Public API**: Only `pipelines/` and `jobs/` templates carry SemVer compatibility guarantees. Everything else can change freely as long as no public template's parameters, outputs, or documented behaviour change as a result. See [Versioning Policy](docs/developers/reference/versioning-policy.md).
- **Tags are immutable**: Releases are tagged `MAJOR.MINOR.PATCH` only. No moving tags (`v1`), no re-pointing a pushed tag.
- **No double-wrapping**: A template must not wrap another template purely to preset defaults. See [Double Wrapping](docs/developers/explanation/double-wrapping.md).
- **PowerShell is the default scripting language** for anything YAML compile-time expressions and built-in tasks cannot do. See [Scripts & Tooling](docs/developers/reference/scripts-and-tooling.md).
- **The pipeline definitions and gate checks for `main` are managed via `cicd/` Terraform**, not via template `feature/<name>` branches. See [Branching Model](docs/developers/reference/branching-model.md).
