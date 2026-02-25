---
description: 'Run a full repository-wide audit across all template types for documentation, best practices, and anti-patterns'
mode: 'edit'
---

Perform a complete audit across the entire repository. Check every template against its
documentation requirements, parameter best practices, and anti-pattern rules. Report all issues
found.

## Audit scope

### 1. Task and Utility Templates (`tasks/`, `utils/`)

For each `.yml` file in these directories:

#### Documentation

- Verify the filename is `snake_case` based on the template's purpose (not the Azure DevOps
  task name)
- Verify a comment block exists at the top with Purpose, Parameters, Example Usage, and Notes
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
- Verify the task version in the comment matches the task version in `steps:`
- Verify Notes include a `See:` link to the Microsoft task reference docs when available

#### Parameters

- Every parameter must have `name`, `type`, and `displayName`
- Parameters without a default must have `# NO default - Consumer must provide this` and
  `(required)` at the end of `displayName`
- Parameter names must use PascalCase and full words (e.g., `TerraformVersion` not `tfVer`)

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

### 4. Anti-patterns (all templates)

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

### 5. Formatting (all files)

Check every `.yml` and `.md` file in the repository against `.editorconfig` rules. Fix any
violations found:

- **Line endings** — All lines must use LF (`\n`), not CRLF (`\r\n`). Convert any CRLF files.
- **Indentation** — YAML files must use 2-space indentation, no tabs. Markdown files must use
  2-space indentation for nested lists.
- **Trailing whitespace** — No line may end with trailing spaces or tabs. Trim them.
- **Final newline** — Every file must end with exactly one newline character. Remove extra
  trailing blank lines; add a newline if missing.
- **Tab characters** — No tab characters anywhere in the file. Replace with spaces.

### 6. Cross-cutting checks

- Verify all relative links between documentation files are valid
- Check that `CHANGELOG.md` exists and has entries

## Output

Produce a summary table:

| File | Issue | Severity |
|------|-------|----------|
| ...  | ...   | ...      |

Then apply fixes for any issues found.

