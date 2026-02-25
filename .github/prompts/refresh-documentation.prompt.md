---
description: 'Full documentation refresh — sync all external docs with current template code'
mode: 'edit'
---

Perform a full documentation refresh across the repository. Read every template and compare it
against its corresponding documentation. Fix any drift so that documentation accurately reflects
the current code.

Do not modify template code — only update documentation files and in-file comment blocks.

## 1. Pipeline Templates (`pipelines/` → `docs/user-docs/`)

Use this mapping to find the documentation file for each pipeline:

| Pipeline Template                       | Documentation File                          |
|-----------------------------------------|---------------------------------------------|
| `pipelines/infrastructure_pipeline.yml` | `docs/user-docs/infrastructure_pipeline.md` |

If a pipeline template has no matching documentation file, create one and add an entry to
`docs/user-docs/README.md`.

For each pipeline and its documentation file:

- **Parameters** — Read the `parameters:` block in the pipeline template. For each parameter,
  verify the documentation has an accurate entry in the parameter table (name, type, default,
  description). Add any new parameters, remove any deleted parameters, and update any that were
  renamed or had their type/default changed.
- **Usage examples** — Verify the Basic Usage and Advanced Usage YAML examples are copy-paste
  accurate with current parameter names and defaults. Fix any that are stale.
- **Breaking changes** — If a parameter was removed, renamed, or had its type changed, add a
  clear migration note explaining what changed and what consumers need to do.
- **Downstream links** — If the pipeline consumes `EnvironmentConfigs` or other complex objects
  validated by a schema, verify that links to `docs/definition_docs/` are still valid.

## 2. Schema Templates (`schemas/` → `docs/definition_docs/`)

Use this mapping to find the documentation files for each schema:

| Schema Template                     | Definition Docs                                                         |
|-------------------------------------|-------------------------------------------------------------------------|
| `schemas/infrastructure_config.yml` | `docs/definition_docs/infrastructure_pipeline/infrastructure_config.md` |
|                                     | `docs/definition_docs/infrastructure_pipeline/environment_config.md`    |

If a schema template has no matching documentation, create the definition doc(s) and link from
the schema's comment block.

For each schema and its definition docs:

- **In-file comment block** — Verify the brief comment block at the top of the schema `.yml`
  file is still accurate. Only update it if the schema's purpose or scope has fundamentally
  changed:

  ```yaml
  # Schema Template: [Name]
  # [One-line description of purpose]
  # See: [link to detailed docs]
  ```

- **Validation rules** — Read every `${{ if }}` compile-time check in the schema. For each
  validated property, verify the definition markdown has:
  - Accurate property name, type, and required/optional status
  - Correct accepted values (e.g., `VerificationMode` options)
  - Up-to-date YAML definition block showing the full object shape
  - Accurate examples reflecting the current structure
- **Added rules** — If a new required field or validation was added to the schema, add the
  property to the definition doc with its type, description, and an example.
- **Removed or relaxed rules** — If a validation rule was removed or a field became optional,
  update the definition doc accordingly.

## 3. Task and Utility Templates (`tasks/`, `utils/`)

These templates use in-file comment blocks as their sole documentation. For each file, verify
the comment block matches the current `parameters:` and `steps:` implementation. This is covered
in detail by the `audit-task-documentation` prompt — only perform a light check here:

- Comment block exists with Purpose, Parameters, Example Usage, and Notes
- Parameter names, types, defaults, and required/optional status match the code

## 4. Cross-cutting checks

After updating individual documentation files:

- **Link integrity** — Verify all relative links between `docs/user-docs/`,
  `docs/definition_docs/`, and schema comment blocks are valid. Fix any broken links caused by
  renames or moves.
- **README index** — Verify `docs/user-docs/README.md` lists all pipeline templates and their
  documentation files.
- **Cascade consistency** — If a schema change affects the shape of objects consumed by a
  pipeline (e.g., `EnvironmentConfigs`, `InfrastructureConfig`), verify that both
  `docs/definition_docs/` and `docs/user-docs/` reflect the same current structure.

## Output

Produce a summary table of all changes made:

| File | What Changed |
|------|--------------|
| ...  | ...          |

