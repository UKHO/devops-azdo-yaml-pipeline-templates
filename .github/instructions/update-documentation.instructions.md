---
description: 'Automatically update documentation when Azure DevOps pipeline template code changes require documentation updates'
applyTo: '**/*.{yml,yaml,md}'
---

# Update Documentation on Template Change

## Overview

This repository has distinct documentation paths depending on which type of template is
modified. When making code changes, documentation **must** be updated in the same change to keep
everything synchronised.

All template files use the `.yml` extension, never `.yaml`. This applies to every path pattern
referenced below.

See [Architecture](../../ARCHITECTURE.md#documentation-location-by-folder) for the canonical
rule on where each template type's documentation lives. The sections below describe *what* to
update and *when*.

**Documentation path convention:** external docs mirror the template's path. A template at
`<area>/<name>.yml` has its consumer documentation at `docs/user-docs/<area>/<name>.md` (for
`pipelines/` and `jobs/`). Schema definition docs live under `docs/definition_docs/`, grouped
by the consuming pipeline (e.g. `docs/definition_docs/terraform_pipeline/`) or `shared/` when
reused across pipelines.

## Documentation Paths by Template Type

### 1. Task and Utility Templates (`tasks/`, `utils/`)

**Documentation location:** In-file comment block at the top of the `.yml` file.

When a task or utility template is modified, update the comment block at the top of that same file
to reflect the changes. The comment block is the **sole documentation** for these templates.

**What to update:**

- **Purpose** — If the template's behaviour changes, update the description
- **Parameters** — If parameters are added, removed, renamed, or have their type/default changed,
  update the parameters list
- **Example Usage** — If parameter changes make existing examples invalid, update them. Add new
  examples if new parameters introduce distinct usage patterns
- **Notes** — If new limitations, considerations, or gotchas are introduced, document them

**Comment block format:**

```yaml
# Azure DevOps Task: [TaskName]@[Version]
#
# Purpose:
#   [Clear, concise description of what the template does]
#
# Parameters:
#   - [ParamName] ([type], [optional/required]): [Description]. Default: [value]
#
# Example Usage:
#   - template: tasks/[template-name].yml
#     parameters:
#       ParamName: 'value'
#
# Notes:
#   - [Important considerations, limitations, or gotchas]
#   - [Links to relevant Azure DevOps documentation if applicable]
```

**Trigger conditions:**

- Parameter added, removed, renamed, or type changed
- Default value changed
- New task version adopted (e.g., `PowerShell@2` → `PowerShell@3`)
- Behaviour change (new conditions, inputs, or outputs)
- Bug fix that changes expected usage

### 2. Pipeline and Job Templates (`pipelines/`, `jobs/`)

**Documentation location:** External markdown files that mirror the template path —
`docs/user-docs/pipelines/<name>.md` for pipelines, `docs/user-docs/jobs/<name>.md` for jobs.

These templates should **NOT** have comprehensive in-file comment blocks. They rely on
self-documenting parameter names with `displayName` attributes. Comprehensive documentation lives
in `docs/user-docs/`.

**Required format (keep it concise).** These docs follow a consistent, minimal structure.
Do **not** add verbose parameter tables or long prose for job docs — the commented-defaults
invocation block is the primary parameter reference. Each doc must follow this skeleton:

1. **H1 title** followed by a **single one-line description** of what the template does.
2. **Commented-defaults invocation block** — a `yaml` block showing the real `jobs:`/`stages:`
   invocation with **every parameter commented out at its default value**, each with an aligned
   inline `#` comment explaining it. Mark lists with `(list)` and note which parameters are
   required. For object-list parameters, show the item structure as commented example lines.
   Open with a comment stating that no parameters are required and every value is shown at its
   default (adjust wording when some are genuinely required).
3. **`---` horizontal rules** separating each major section.
4. **Output / Artifact section** (where relevant) — e.g. an artifact file tree or output-variable
   syntax.
5. **`## Examples`** — named scenario subsections (`### <Scenario>`), each a focused, runnable
   YAML snippet. Add a `**Live example**:` link to a real file under `tests/jobs/.../*.yml`
   (or `tests/stages/...` / `tests/pipelines/...`) wherever one exists.
6. **`## See Also`** — relative cross-links to related job, pipeline, and schema docs.

**Commented-defaults block example:**

```yaml
jobs:
  - template: jobs/<name>.yml
    parameters:
      # No parameters are required - every value below is shown at its default. Uncomment and change a value to override it.

      # ParamName: 'default'          # Aligned inline explanation of the parameter.
      # ListParam:                    # (list) What it does. Defaults to an empty list.
```

**What to update when the template changes:**

- **Commented-defaults block** — If parameters are added, removed, renamed, or their default/type
  changes, update the block (and its inline comments) to match exactly
- **Examples** — If parameter changes affect how consumers reference the template, update the
  affected named scenarios and their `**Live example**` links
- **Breaking changes** — Document what changed, why, and how consumers should migrate
- **New features** — Add a new named example scenario demonstrating the capability

**Mapping:** the doc path mirrors the template path. Examples:

| Template                            | Documentation File                          |
|-------------------------------------|---------------------------------------------|
| `pipelines/terraform_pipeline.yml`  | `docs/user-docs/pipelines/terraform_pipeline.md` |
| `jobs/terraform_build.yml`          | `docs/user-docs/jobs/terraform_build.md`    |

When a new pipeline or job template is added, create the corresponding mirrored documentation
file and add an entry to `docs/user-docs/README.md`.

**Trigger conditions:**

- Parameter added, removed, renamed, or default changed
- New stage or environment behaviour introduced
- Structure changes (new stages/jobs, changed ordering, new dependencies)
- Changes to how complex object parameters are consumed

### 2a. Stage Templates (`stages/`)

Stage templates follow the same rule as jobs: no comprehensive in-file block; document consumer-facing
behaviour in `docs/user-docs/` where the stage is complex enough to warrant it.

### 3. Schema Templates (`schemas/`)

**Documentation location:** Both the in-file comment block **and** external markdown files in
`docs/definition_docs/`.

Schema templates have a brief comment block at the top of the `.yml` file and detailed definition
documentation in `docs/definition_docs/`.

**What to update in the `.yml` file:**

- The brief comment block describing the schema's purpose
- Only update if the schema's purpose or scope fundamentally changes

**Brief comment block format:**

```yaml
# Schema Template: [Name]
# [One-line description of purpose]
# See: [link to detailed docs]
```

**What to update in `docs/definition_docs/`:**

- **Property definitions** — If validated fields are added, removed, or changed, update the
  definition markdown with the new structure
- **Required vs optional status** — If a field becomes required or optional, update accordingly
- **Type information** — If accepted types or values change, update the definition
- **YAML examples** — If the expected object shape changes, update all code examples

**Mapping:** schema definition docs live under `docs/definition_docs/`, grouped by the consuming
pipeline or under `shared/` when reused. Examples:

| Schema Template                     | Definition Docs                                                      |
|-------------------------------------|---------------------------------------------------------------------|
| `schemas/config_sources.yml`        | `docs/definition_docs/shared/config_sources.md`                     |
| `schemas/terraform_deploy_config.yml` | `docs/definition_docs/terraform_pipeline/terraform_job_config.md` |

When a new schema template is added, create corresponding definition documentation under
`docs/definition_docs/` (in the consuming pipeline's folder, or `shared/` if reused).

**Trigger conditions:**

- New validation rule added (new required field)
- Validation rule removed or relaxed
- Accepted values changed (e.g., new `VerificationMode` option)
- Object structure changes

## Downstream Documentation Effects

Changes can cascade across documentation. Be aware of these relationships:

| What Changed | Also Update |
|---|---|
| Task/util parameter | In-file comment block |
| Pipeline parameter | `docs/user-docs/pipelines/<name>.md` |
| Job parameter | `docs/user-docs/jobs/<name>.md` |
| Schema validation rule | Schema comment block + `docs/definition_docs/` markdown |
| Schema validation rule | `docs/user-docs/` markdown (if it affects pipeline usage) |
| New pipeline or job template | `docs/user-docs/README.md` (add entry) |
| Breaking change (any) | `CHANGELOG.md` |

## CHANGELOG.md Updates

**Always update `CHANGELOG.md` when:**

- Adding new templates or parameters (under **Added**)
- Changing existing behaviour (under **Changed**, prefix with **BREAKING** if applicable)
- Fixing bugs (under **Fixed**)
- Removing templates or parameters (under **Removed**)
- Deprecating features (under **Deprecated**)

**Format:** Add entries under the existing `## [Unreleased]` heading at the top of `CHANGELOG.md`, in the matching subsection:

```markdown
## [Unreleased]

### Added
- New feature or template description

### Changed
- **BREAKING**: Description of breaking change
- Non-breaking change description

### Fixed
- Bug fix description
```

## Documentation Quality Guidelines

### Writing Style

- Use clear, concise language
- Be specific — name the exact parameter, template, or file affected
- Include working YAML examples that consumers can copy and adapt
- Document limitations, edge cases, and gotchas
- Use consistent terminology throughout (match parameter names exactly)

### YAML Examples in Documentation

All YAML examples in markdown files should be:

- Complete enough to be useful (include required parameters)
- Accurate (match current template parameters and defaults)
- Formatted consistently (2-space indentation, matching `.editorconfig`)

### Links

- Use relative links between documentation files
- Link from `docs/user-docs/` to `docs/definition_docs/` for complex object parameters
- Verify links are not broken after file renames or moves

## Review Checklist

Before considering documentation complete:

- [ ] In-file comment blocks in `tasks/` and `utils/` reflect current parameters and behaviour
- [ ] External documentation in `docs/user-docs/` reflects current pipeline and job parameters and usage
- [ ] Job/pipeline docs follow the concise format: one-line description, commented-defaults invocation block, named examples with live-test links, and a See Also section
- [ ] Schema comment blocks and `docs/definition_docs/` reflect current validation rules
- [ ] YAML examples in documentation are accurate and runnable
- [ ] `CHANGELOG.md` is updated for significant changes
- [ ] Links between documentation files are valid
- [ ] `docs/user-docs/README.md` lists all pipeline and job templates
