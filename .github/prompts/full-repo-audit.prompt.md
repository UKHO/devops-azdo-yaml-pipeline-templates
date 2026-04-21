---
description: 'Run a full repository-wide audit across all template types for documentation, best practices, and anti-patterns'
mode: 'edit'
---

Perform a complete audit across the entire repository. Check every template against its
documentation requirements, parameter best practices, and anti-pattern rules. Report all issues
found.

**Important:** Do NOT create or modify comprehensive in-file comment documentation blocks for 
templates in `/pipelines/`, `/jobs/`, and `/stages/` directories. These rely on external 
documentation in `docs/` or are consumed via parent template parameter documentation. Schemas 
have brief comment blocks only (3-4 lines linking to external docs).

## Audit scope

### 1. Task and Utility Templates (`tasks/`, `utils/`)

For each `.yml` file in these directories, a comment block at the top is the **sole documentation**.

#### Documentation in Comment Block

- Verify the filename is `snake_case` based on the template's purpose (not the Azure DevOps
  task name)
- Verify a comment block exists at the top with: Purpose, Parameters, Example Usage, and Notes
- Compare every parameter in the `parameters:` block against the comment block — flag mismatches
  in name, type, default value, or required/optional status
- Verify enum parameter descriptions include `Values: a, b, c.` suffix
- Verify conditionally required parameters are documented as `optional` with a note on the
  condition (e.g., "required when deploying to a slot")
- Verify required enum parameters (those with `values:` and no `default:`) use the
  `# NO default` comment and `(required)` in `displayName`
- Verify parameter property ordering follows `name` → `type` → `default` → `values` →
  `displayName`
- Verify examples reference correct parameter names
- Verify three-or-more examples use `# Description` label comments on additional examples
- Verify the task version in the comment matches the task version in `steps:` (if wrapping an
  Azure DevOps task)
- Verify Notes include a `See:` link to the Microsoft task reference docs when available

#### Parameters

- Every parameter must have `name`, `type`, and `displayName`
- Parameters without a default must have `# NO default - Consumer must provide this` and
  `(required)` at the end of `displayName`
- Parameter names must use PascalCase and full words (e.g., `TerraformVersion` not `tfVer`)

### 2. Pipeline Templates (`pipelines/`)

For each `.yml` file in this directory, **do NOT add comment blocks**. External documentation is the
sole source of truth.

#### External Documentation

- Verify a corresponding markdown file exists in `docs/user-docs/pipelines/`
- Verify the pipeline is listed in `docs/user-docs/README.md` under the Pipeline Templates section
- Compare every parameter in the pipeline template against the documentation — flag any parameters
  that are missing, renamed, or have incorrect defaults in the docs
- Verify YAML examples in the docs use current parameter names and defaults
- Verify the pipeline file itself uses self-documenting parameters with `displayName` and appropriate
  types

### 3. Job Templates (`jobs/`)

For each `.yml` file in this directory, **do NOT add comment blocks**. External documentation is the
sole source of truth for documented job templates.

#### External Documentation

- Verify a corresponding markdown file exists in `docs/user-docs/jobs/` for each documented job
  template (not all jobs require external documentation if internal-only)
- Verify documented jobs are listed in `docs/user-docs/README.md` under the Job Templates section
- Compare every parameter in the job template against the documentation — flag any parameters
  that are missing, renamed, or have incorrect defaults in the docs
- Verify YAML examples in the docs use current parameter names and defaults
- Verify the job file itself uses self-documenting parameters with `displayName` and appropriate
  types

### 4. Schema Templates (`schemas/`)

For each `.yml` file in this directory:

#### Comment Block (Brief)

- Verify a brief comment block exists at the top (3-4 lines) with:
  - Schema name
  - One-line description of purpose
  - Link to detailed definition docs
- Example format:
  ```yaml
  # Schema Template: [Name]
  # [One-line description of purpose]
  # See: docs/definition_docs/infrastructure_pipeline/[name].md
  ```

#### External Definition Documentation

- Verify corresponding definition docs exist in `docs/definition_docs/`
- Compare every validation rule in the schema against the definition docs — flag any validated
  properties that are missing or incorrect in the docs
- Verify accepted values (e.g., `VerificationMode` options) match between schema and docs

### 5. Stage Templates (`stages/`)

For each `.yml` file in this directory:

- **Do NOT add comment documentation blocks.** These are orchestration templates that rely on
  external documentation in consuming pipelines or are consumed via parameter documentation in 
  parent templates.
- Verify parameters use self-documenting names with descriptive `displayName` attributes
- Verify parameters have appropriate `type` and `default` values where applicable

### 6. Anti-patterns (all templates)

For every `.yml` template file in `tasks/`, `utils/`, `jobs/`, `stages/`, `pipelines/`:

- **Double-wrapping** — Flag any template that wraps another template purely for parameter
  pass-through. Orchestration wrappers (pipeline → stage → job → task) are acceptable.
- **Hardcoded secrets** — Flag any sensitive values (keys, passwords, connection strings) that
  are hardcoded. They must use Azure Key Vault or variable groups instead.
- **Mixed concerns** — Flag any single stage that contains both build and deployment jobs.
- **Secrets in logs** — Flag any secret values at risk of being printed to pipeline logs.
- **Overly permissive service connections** — Flag any patterns that suggest broad permissions
  where scoped connections would be more appropriate.
- **Compile-time vs runtime expressions** — Verify `${{ }}` and `$()` are used appropriately.
  Parameters and template logic should use compile-time; runtime variables should use `$()`.

### 6. Formatting (all files)

Check every `.yml` and `.md` file in the repository against `.editorconfig` rules. Fix any
violations found:

- **Line endings** — All lines must use LF (`\n`), not CRLF (`\r\n`). Convert any CRLF files.
- **Indentation** — YAML files must use 2-space indentation, no tabs. Markdown files must use
  2-space indentation for nested lists.
- **Trailing whitespace** — No line may end with trailing spaces or tabs. Trim them.
- **Final newline** — Every file must end with exactly one newline character. Remove extra
  trailing blank lines; add a newline if missing.
- **Tab characters** — No tab characters anywhere in the file. Replace with spaces.

### 7. Cross-cutting checks

- Verify all relative links between documentation files are valid
- Check that `CHANGELOG.md` exists and has entries

## Output

Produce a summary table:

| File | Issue | Severity |
|------|-------|----------|
| ...  | ...   | ...      |

Then apply fixes for any issues found.

