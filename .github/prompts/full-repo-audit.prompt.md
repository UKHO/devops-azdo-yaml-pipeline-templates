---
description: 'Run a full repository-wide documentation audit across all template types'
mode: 'edit'
---

Perform a complete documentation audit across the entire repository. Check every template against
its documentation requirements and report all issues found.

## Audit scope

### 1. Task and Utility Templates (`tasks/`, `utils/`)

For each `.yml` file in these directories:

- Verify a comment block exists at the top with Purpose, Parameters, Example Usage, and Notes
- Compare every parameter in the `parameters:` block against the comment block — flag mismatches
  in name, type, default value, or required/optional status
- Verify examples reference correct parameter names
- Verify the task version in the comment matches the task version in `steps:`

### 2. Pipeline Templates (`pipelines/`)

For each `.yml` file in this directory:

- Verify a corresponding markdown file exists in `docs/user-docs/`
- Verify the pipeline is listed in `docs/user-docs/README.md`
- Compare every parameter in the pipeline template against the documentation — flag any parameters
  that are missing, renamed, or have incorrect defaults in the docs
- Verify YAML examples in the docs use current parameter names and defaults

### 3. Schema Templates (`schemas/`)

For each `.yml` file in this directory:

- Verify a brief comment block exists at the top
- Verify corresponding definition docs exist in `docs/definition_docs/`
- Compare every validation rule in the schema against the definition docs — flag any validated
  properties that are missing or incorrect in the docs
- Verify accepted values (e.g., `VerificationMode` options) match between schema and docs

### 4. Cross-cutting checks

- Verify all relative links between documentation files are valid
- Check that `CHANGELOG.md` exists and has entries
- Verify `.editorconfig` formatting (no BOM, LF line endings, 2-space indent) on all YAML files

## Output

Produce a summary table:

| File | Issue | Severity |
|------|-------|----------|
| ... | ... | ... |

Then apply fixes for any issues found.

