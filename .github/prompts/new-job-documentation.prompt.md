---
description: 'Generate user documentation for a new job template in docs/user-docs/jobs/'
mode: 'edit'
---

A new job template has been added to `jobs/`. Generate comprehensive user documentation for it in
`docs/user-docs/jobs/`.

## Requirements

Ask me for:

- **Job template file** — which file in `jobs/` to document

Then read the template and generate documentation following the conventions below.

## Steps

### 1. Create the documentation file

Create `docs/user-docs/jobs/{job_name}_job.md` where `{job_name}` matches the template filename
without the `.yml` extension.

### 2. Document structure

The markdown file must follow this section order. Every section is required unless marked
otherwise.

#### Title and introduction

```markdown
# {Job Name} Job

A brief description of what the job does, what tasks it orchestrates, and what it is used for.
Follow with a bullet list of the high-level responsibilities or outputs the job provides.
```

- Use an H1 heading matching the job's purpose (e.g., `# Terraform Deploy Job`).
- Keep the description to two to three sentences.
- List the job's key responsibilities or outputs as bullet points.

#### Important

```markdown
## Important

Highlight critical prerequisites, constraints, and known limitations that consumers must be aware
of before using the job.
```

Include at minimum:

- Environment requirements (pool type, agent requirements)
- Any prerequisites (e.g., "Requires the Terraform Build Job output")
- Any features that are not yet available or not included

#### Basic Usage

```markdown
## Basic Usage

### Example of Basic Usage
```

Provide a complete, copy-paste-ready YAML example that includes:

- Calling the job template with all **required** parameters filled in and realistic example values
- A brief explanation of how the job fits into a stage
- Only required parameters — do not include optional parameters with their defaults

Example format:

```yaml
- template: ../jobs/{job_name}.yml
  parameters:
    RequiredParam: 'value'
```

#### Required Parameters

```markdown
### Required Parameters
```

- Briefly describe each required parameter
- Link to corresponding definition docs in `docs/definition_docs/` if the parameter is a complex
  object
- Include a **quick reference table** of required fields with columns: Parameter Name, Type,
  Description

#### Optional Parameters (optional section)

```markdown
## Optional Parameters
```

If the job has optional parameters, document them with:

- Parameter name and type
- Description of what the parameter does
- Default value
- Examples showing usage patterns

#### Advanced Usage

```markdown
## Advanced Usage
```

Provide one to three distinct advanced examples, each under an H3 heading describing the scenario.
Each example should demonstrate a different optional parameter or usage pattern. Examples must be
valid YAML with 2-space indentation.

#### Troubleshooting (optional)

```markdown
## Troubleshooting
```

If the job has non-obvious failure modes, add an H3 for each issue with **Issue**,
**Check** or **Cause**, and **Solution** sub-sections.

### 3. Update the README index

Add an entry to `docs/user-docs/README.md` under the `## 🔧 Job Templates` section:

```markdown
- **[{Job Name} Job](./jobs/{job_name}_job.md)** – One-line description
```

### 4. Update the mapping table

Add the new job to the mapping tables in:

- `.github/instructions/update-documentation.instructions.md` (Job Template → Documentation
  File table)
- `.github/prompts/refresh-documentation.prompt.md` (Section 2 mapping table)

## Formatting

- Use 2-space indentation inside all YAML code blocks
- Keep line length under 400 characters (break at 80 where practical)
- Use `---` horizontal rules between major sections only where the existing docs use them
- All relative links must use correct paths (e.g., `../definition_docs/...`)
- Quote all string values in YAML examples that could be misinterpreted (versions, booleans as
  strings, etc.)



