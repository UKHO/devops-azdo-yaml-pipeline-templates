---
description: 'Automatically update documentation when Azure DevOps pipeline template code changes require documentation updates'
applyTo: '**/*.{yml,md}'
---

# Update Documentation on Template Change

## Overview

This repository has three distinct documentation paths depending on which type of template is
modified. When making code changes, documentation **must** be updated in the same change to keep
everything synchronised.

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

### 2. Pipeline Templates (`pipelines/`)

**Documentation location:** External markdown files in `docs/user-docs/`.

Pipeline templates themselves should **NOT** have in-file comment blocks. They rely on
self-documenting parameter names with `displayName` attributes. Comprehensive documentation lives
in the `docs/user-docs/` directory.

**What to update in `docs/user-docs/`:**

- **Parameter documentation** — If pipeline parameters are added, removed, or changed, update the
  parameter tables and descriptions in the corresponding markdown file
- **Usage examples** — If parameter changes affect how consumers reference the pipeline, update the
  basic and advanced usage examples
- **Breaking changes** — Document what changed, why, and how consumers should migrate
- **New features** — Add sections describing new capabilities with examples

**Mapping:**

| Pipeline Template                       | Documentation File                          |
|-----------------------------------------|---------------------------------------------|
| `pipelines/infrastructure_pipeline.yml` | `docs/user-docs/infrastructure_pipeline.md` |

When a new pipeline template is added, create a corresponding documentation file in
`docs/user-docs/` and add an entry to `docs/user-docs/README.md`.

**Trigger conditions:**

- Parameter added, removed, renamed, or default changed
- New stage or environment behaviour introduced
- Pipeline structure changes (new stages, changed ordering, new dependencies)
- Changes to how `EnvironmentConfigs` or other complex objects are consumed

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

**Mapping:**

| Schema Template                     | Definition Docs                                                         |
|-------------------------------------|-------------------------------------------------------------------------|
| `schemas/infrastructure_config.yml` | `docs/definition_docs/infrastructure_pipeline/infrastructure_config.md` |
|                                     | `docs/definition_docs/infrastructure_pipeline/environment_config.md`    |

When a new schema template is added, create corresponding definition documentation in
`docs/definition_docs/`.

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
| Pipeline parameter | `docs/user-docs/` markdown |
| Schema validation rule | Schema comment block + `docs/definition_docs/` markdown |
| Schema validation rule | `docs/user-docs/` markdown (if it affects pipeline usage) |
| New pipeline template | `docs/user-docs/README.md` (add entry) |
| Breaking change (any) | `CHANGELOG.md` |

## CHANGELOG.md Updates

**Always update `CHANGELOG.md` when:**

- Adding new templates or parameters (under **Added**)
- Changing existing behaviour (under **Changed**, prefix with **BREAKING** if applicable)
- Fixing bugs (under **Fixed**)
- Removing templates or parameters (under **Removed**)
- Deprecating features (under **Deprecated**)

**Format:**

```markdown
## [Version] - YYYY-MM-DD

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
- [ ] External documentation in `docs/user-docs/` reflects current pipeline parameters and usage
- [ ] Schema comment blocks and `docs/definition_docs/` reflect current validation rules
- [ ] YAML examples in documentation are accurate and runnable
- [ ] `CHANGELOG.md` is updated for significant changes
- [ ] Links between documentation files are valid
- [ ] `docs/user-docs/README.md` lists all pipeline templates
