# GitHub Copilot Instructions & Prompts

This repository includes a set of **instruction files** and **prompt files** under `.github/` that integrate with GitHub Copilot. They encode the repository's conventions so that AI-assisted work stays consistent without requiring developers to memorise every rule.

---

## How It Works

GitHub Copilot supports two mechanisms for repository-level guidance:

- **Instruction files** (`.github/instructions/`) — automatically applied based on the file type you are editing. They act as persistent context that Copilot receives whenever a matching file is open.
- **Prompt files** (`.github/prompts/`) — on-demand templates you invoke explicitly to perform a specific task. Think of them as reusable recipes.

Both rely on the top-level `.github/copilot-instructions.md` file, which provides the high-level context about the repository's structure and principles. The instruction and prompt files build on that foundation with detailed, targeted rules.

---

## Instruction Files

Instruction files are applied **automatically** by Copilot whenever you work on a file that matches their `applyTo` glob. You do not need to invoke them — they are always active in the background.

### Overview

| File                                     | Applies To      | Purpose                                                                                                                                   |
|------------------------------------------|-----------------|-------------------------------------------------------------------------------------------------------------------------------------------|
| `azure-devops-pipelines.instructions.md` | `**/*.yml`      | YAML formatting, template documentation strategy, parameter best practices, anti-patterns, breaking changes, security, naming conventions |
| `update-documentation.instructions.md`   | `**/*.{yml,md}` | When and how to update documentation for each template type, CHANGELOG management, downstream documentation effects                       |
| `markdown.instructions.md`               | `**/*.md`       | Markdown formatting, structure, and validation rules                                                                                      |

### `azure-devops-pipelines.instructions.md`

**Applies to:** all `.yml` files

This is the most comprehensive instruction file. It covers:

- **Formatting standards** — `.editorconfig` rules (LF, 2-space indent, no trailing whitespace)
- **Template documentation strategy** — which templates get in-file comment blocks
  (`tasks/`, `utils/`) vs. external docs (`pipelines/`, `jobs/`, `stages/`)
- **Parameter best practices** — `displayName`, `type`, `default`, property ordering, required vs. optional conventions
- **Variable best practices** — compile-time vs. runtime expressions
- **Anti-patterns** — double-wrapping, hardcoded secrets, mixed concerns, overly broad triggers
- **Breaking changes and versioning** — SemVer rules
- **Security** — secrets management, service connections
- **Naming conventions** — PascalCase parameters, `snake_case` filenames

When you ask Copilot to create or modify a `.yml` file, it will follow all of these rules
without you having to specify them.

### `update-documentation.instructions.md`

**Applies to:** all `.yml` and `.md` files

This instruction file ensures documentation stays synchronised with code. It defines:

- **Documentation paths by template type** — tasks/utils use in-file comment blocks, pipelines
  use `docs/user-docs/`, schemas use both in-file comments and `docs/definition_docs/`
- **Trigger conditions** — when documentation must be updated (parameter changes, new task
  versions, behaviour changes)
- **Downstream effects** — a cascade table showing which docs to update when something changes
- **CHANGELOG.md rules** — when and how to add entries
- **Quality guidelines** — writing style, YAML example accuracy, link validation

When you make a code change and ask Copilot to help, it will automatically know which documentation files need updating.

### `markdown.instructions.md`

**Applies to:** all `.md` files

A concise set of markdown formatting rules:

- Heading hierarchy (avoid H4+)
- List formatting (use `-` for bullets, 2-space indent for nesting)
- Fenced code blocks with language specifiers
- Line length limits (break at 80 characters, hard limit of 400)
- Proper link and image syntax

---

## Prompt Files

Prompt files are **on-demand** — you choose when to run them. Each prompt is designed for a specific task and will guide Copilot through a multi-step workflow.

### Overview

| Prompt                         | Mode | When to Use                                                             |
|--------------------------------|------|-------------------------------------------------------------------------|
| `new-task-template`            | Edit | Creating a new task wrapper in `tasks/`                                 |
| `new-pipeline-scaffold`        | Edit | Scaffolding a pipeline → stage → job template chain                     |
| `new-schema-template`          | Edit | Creating a compile-time validation template in `schemas/`               |
| `new-pipeline-documentation`   | Edit | Writing user docs for a new pipeline in `docs/user-docs/`               |
| `new-definition-documentation` | Edit | Writing definition docs for a complex object in `docs/definition_docs/` |
| `audit-task-documentation`     | Edit | Auditing an existing task/util template's comment block                 |
| `refresh-documentation`        | Edit | Syncing all documentation with current template code                    |
| `full-repo-audit`              | Edit | Running a complete repository-wide audit                                |

### Creating New Templates

#### `new-task-template`

**Use when:** you need to add a new task wrapper template to `tasks/`.

Copilot will ask for the Azure DevOps task name and version, the template's purpose, and the parameters to expose. It then generates a complete `.yml` file with:

- A full in-file comment block (Purpose, Parameters, Example Usage, Notes)
- Correctly structured parameters with `displayName`, proper ordering, and required/optional conventions
- A `steps:` block invoking the Azure DevOps task with conditional inputs

#### `new-pipeline-scaffold`

**Use when:** you need to create a new pipeline and its supporting stage and job templates.

Copilot will ask for a short name and a one-line purpose, then generate three connected files:

- `pipelines/{name}_pipeline.yml` — the pipeline template
- `stages/{name}.yml` — the stage template
- `jobs/{name}.yml` — the job template

All parameters are wired together with explicit pass-through. The scaffold includes a `PipelinePool` parameter, `workspace: clean: all`, and placeholder steps so the chain is immediately runnable.

#### `new-schema-template`

**Use when:** you need to add compile-time validation for a complex object parameter.

Copilot will ask for the object name, its properties (required and optional with types), and which template consumes it. It then generates a schema template in `schemas/` with:

- A brief three-line comment block
- Parameters for the object and a context identifier (e.g., `EnvironmentName`)
- Compile-time `${{ if }}` validation rules for required fields, enums, all-or-nothing groups, and type checks

### Creating Documentation

#### `new-pipeline-documentation`

**Use when:** a new pipeline template has been added to `pipelines/` and needs user-facing documentation.

Copilot reads the pipeline template and generates a markdown file in `docs/user-docs/` with:

- Title, introduction, and stage overview
- Important prerequisites and constraints
- A copy-paste-ready Basic Usage example with only required parameters
- Required parameter quick-reference table with links to definition docs
- Advanced Usage examples demonstrating optional parameters
- Updates to `docs/user-docs/README.md` and the mapping tables in instruction/prompt files

#### `new-definition-documentation`

**Use when:** a schema validates a complex object parameter that needs detailed property-level documentation.

Copilot reads the schema's validation rules and generates a markdown file in `docs/definition_docs/` with:

- A YAML definition block annotated with `# REQUIRED` / `# OPTIONAL`
- Separate sections for required and optional properties (type, description, example, allowed
  values)
- A complete example with all properties filled in
- See Also links to related docs
- Updates to schema comment blocks and mapping tables

### Auditing & Refreshing

#### `audit-task-documentation`

**Use when:** you want to verify that a specific task or utility template's in-file comment block is accurate.

Run this on a single `tasks/` or `utils/` file. Copilot compares the comment block against the actual `parameters:` and `steps:` sections and fixes:

- Missing or incomplete comment blocks
- Parameter mismatches (name, type, default, required/optional)
- Stale examples referencing old parameter names
- Wrong task versions in the header
- Incorrect parameter property ordering
- Missing `See:` links to Microsoft documentation

#### `refresh-documentation`

**Use when:** you want to sync all external documentation with the current template code in a single pass.

Copilot reads every template and compares it against its corresponding documentation. It updates:

- Pipeline docs in `docs/user-docs/` (parameter tables, usage examples)
- Schema docs in `docs/definition_docs/` (validation rules, property definitions)
- Task/util in-file comment blocks (light check)
- Cross-cutting concerns (link integrity, README index, cascade consistency)

#### `full-repo-audit`

**Use when:** you want a comprehensive check of the entire repository against all conventions.

This is the broadest prompt. It covers everything the other audit prompts cover, plus:

- Anti-pattern detection (double-wrapping, hardcoded secrets, mixed concerns)
- `.editorconfig` compliance (line endings, indentation, trailing whitespace)
- Parameter best practices across all template types
- Cross-cutting link and CHANGELOG validation

It produces a summary table of all issues found with severity levels, then applies fixes.

---

## When to Use What

| Scenario                                   | What to Use                                           |
|--------------------------------------------|-------------------------------------------------------|
| Editing a `.yml` file                      | Instructions apply automatically — just work normally |
| Editing a `.md` file                       | Instructions apply automatically — just work normally |
| Adding a new task template                 | Run `new-task-template` prompt                        |
| Adding a new pipeline with stages and jobs | Run `new-pipeline-scaffold` prompt                    |
| Adding a schema for object validation      | Run `new-schema-template` prompt                      |
| Documenting a new pipeline                 | Run `new-pipeline-documentation` prompt               |
| Documenting a complex object parameter     | Run `new-definition-documentation` prompt             |
| Checking a single task's documentation     | Run `audit-task-documentation` prompt                 |
| Syncing all docs after a batch of changes  | Run `refresh-documentation` prompt                    |
| Full repository health check               | Run `full-repo-audit` prompt                          |
| Updating documentation alongside code      | Instructions handle this automatically                |

---

[← Back to Developer Documentation](README.md)

