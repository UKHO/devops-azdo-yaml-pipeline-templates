---
description: 'Scaffold a new pipeline → stage → job template chain with wiring already connected'
mode: 'edit'
---

Scaffold a new set of connected templates: a pipeline that calls a stage that calls a job. All
three files are created with parameters wired together and ready to build on.

## Requirements

Ask me for:

- **Name** — a short name for the template set (e.g., `dotnet_build`, `docker_deploy`). This
  is used to derive filenames.
- **Purpose** — a one-line description of what the pipeline does

Then generate all three files following the conventions below.

## Files to create

| Template | File                            | Calls                      |
|----------|---------------------------------|----------------------------|
| Pipeline | `pipelines/{name}_pipeline.yml` | `stages/{name}.yml`        |
| Stage    | `stages/{name}.yml`             | `jobs/{name}.yml`          |
| Job      | `jobs/{name}.yml`               | task templates in `tasks/` |

## Conventions

### Parameter flow

Parameters that consumers provide at the pipeline level must flow down through the stage and
into the job. Follow these rules:

- Define parameters at the **highest level they are needed** (typically the pipeline).
- Pass parameters down explicitly — never rely on variable inheritance across templates.
- Each template re-declares the parameters it receives with their own `name`, `type`,
  `default`, and `displayName`.
- Use the same parameter name at every level unless the scope changes (e.g., a pipeline-level
  list becomes a single item at the stage level).

### Pipeline template (`pipelines/{name}_pipeline.yml`)

```yaml
parameters:
  - name: ParamA
    type: string
    default: ''
    displayName: 'Description'

  # ... pipeline-specific parameters ...

stages:
  - template: ../stages/{name}.yml
    parameters:
      ParamA: ${{ parameters.ParamA }}
```

- Define all pipeline-specific parameters at this level with appropriate `displayName` and defaults.
- The `stages:` block calls the stage template with explicit parameter pass-through.
- **Note:** The `pool:` element must be defined in the root `azure-pipelines.yml` file, not in the pipeline template (it cannot be templated).

### Stage template (`stages/{name}.yml`)

```yaml
parameters:
  - name: ParamA
    type: string
    default: ''
    displayName: 'Description'

stages:
  - stage: {StageName}
    displayName: '{Stage Display Name}'
    jobs:
      - template: ../jobs/{name}.yml
        parameters:
          ParamA: ${{ parameters.ParamA }}
```

- Re-declare every parameter received from the pipeline.
- Define a single stage with a descriptive `displayName`.
- The `jobs:` block calls the job template with explicit parameter pass-through.

### Job template (`jobs/{name}.yml`)

```yaml
parameters:
  - name: ParamA
    type: string
    default: ''
    displayName: 'Description'

jobs:
  - job: {JobName}
    displayName: '{Job Display Name}'
    workspace:
      clean: all
    steps:
      - checkout: self
        displayName: 'Checkout repository'

      # TODO: Add task template calls here
      - script: echo "Hello from {name} job"
        displayName: 'Placeholder step'
```

- Re-declare every parameter received from the stage.
- Include `workspace: clean: all` and a `checkout: self` step as a starting point.
- Add a placeholder step with a `# TODO` comment so the file is immediately runnable.

### Parameter conventions (same as task templates)

- Every parameter must have `name`, `type`, `default` (or `# NO default`), and `displayName`.
- Property order: `name` → `type` → `default` → `values` → `displayName`.
- Required parameters use `# NO default - Consumer must provide this` and `(required)` in
  `displayName`.
- PascalCase parameter names, full words.

## Formatting

All files must match `.editorconfig`:

- 2-space indentation, no tabs
- LF line endings
- No trailing whitespace
- File ends with exactly one newline (no trailing blank lines)

## After scaffolding

Print a short summary of the three files created and the parameter flow between them, so the
consumer knows where to start adding their logic.

