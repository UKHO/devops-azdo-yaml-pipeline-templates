---
description: 'Generate user documentation for a new pipeline template in docs/user-docs/'
mode: 'edit'
---

A new pipeline template has been added to `pipelines/`. Generate comprehensive user
documentation for it in `docs/user-docs/`.

## Requirements

Ask me for:

- **Pipeline template file** — which file in `pipelines/` to document

Then read the template and generate documentation following the conventions below.

## Steps

### 1. Create the documentation file

Create `docs/user-docs/{pipeline_name}.md` where `{pipeline_name}` matches the template
filename without the `.yml` extension.

### 2. Document structure

The markdown file must follow this section order. Every section is required unless marked
otherwise.

#### Title and introduction

```markdown
# {Pipeline Name}

A brief description of what the pipeline does, what tooling it uses, and what cloud provider
it targets. Follow with a bullet list of the high-level stages the pipeline performs.
```

- Use an H1 heading matching the pipeline's purpose (e.g., `# Infrastructure Pipeline`).
- Keep the description to two to three sentences.
- List the pipeline's stages as bullet points.

#### Important

```markdown
## Important

Highlight critical prerequisites, constraints, and known limitations that consumers must be
aware of before using the pipeline.
```

Include at minimum:

- Repository resource requirements (name the expected `repository` alias)
- Pool requirements (state the default pool and how to override it)
- Any features that are not yet available or not included

#### Basic Usage

```markdown
## Basic Usage

### Example of Basic Usage
```

Provide a complete, copy-paste-ready `azure-pipelines.yml` example that includes:

- `resources.repositories` block referencing this template repository with a `ref: refs/tags/`
  placeholder
- `trigger` block
- `extends` block calling the pipeline template with all **required** parameters filled in and
  realistic example values
- Only required parameters — do not include optional parameters with their defaults

#### Required Parameters

```markdown
### Required Parameters
```

- Briefly describe the most complex required parameter (typically the object parameter such as
  `EnvironmentConfigs`).
- Link to the corresponding definition docs in `docs/definition_docs/` for full structure.
- Include a **quick reference table** of required fields with columns: Field Path, Type,
  Description.

#### Advanced Usage

```markdown
## Advanced Usage
```

Provide two to four distinct advanced examples, each under an H3 heading describing the
scenario. Each example should demonstrate a different optional parameter or usage pattern.
Examples must be valid YAML with 2-space indentation.

Include an invitation for contributions:

```markdown
_If you have any advanced usages, please consider contributing them to the documentation._
```

#### Troubleshooting (optional)

```markdown
## Troubleshooting
```

If the pipeline has non-obvious failure modes, add an H3 for each issue with **Issue**,
**Check** or **Cause**, and **Solution** sub-sections.

### 3. Update the README index

Add an entry to `docs/user-docs/README.md` under the `## 📋 Pipeline Templates` section:

```markdown
- **[{Pipeline Name}](./{pipeline_name}.md)** – One-line description
```

### 4. Update the mapping table

Add the new pipeline to the mapping tables in:

- `.github/instructions/update-documentation.instructions.md` (Pipeline Template → Documentation
  File table)
- `.github/prompts/refresh-documentation.prompt.md` (Section 1 mapping table)

## Formatting

- Use 2-space indentation inside all YAML code blocks
- Keep line length under 400 characters (break at 80 where practical)
- Use `---` horizontal rules between major sections only where the existing docs use them
- All relative links must use correct paths (e.g., `../definition_docs/...`)
- Quote all string values in YAML examples that could be misinterpreted (versions, booleans as
  strings, etc.)

