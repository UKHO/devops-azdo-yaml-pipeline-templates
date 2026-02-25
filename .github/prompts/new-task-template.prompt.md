---
description: 'Create a new task template with correct structure and documentation'
mode: 'edit'
---

Create a new task template in the `tasks/` directory.

## Filename Convention

Use `snake_case` based on the template's purpose, not the Azure DevOps task name. For example:

| Task                        | Filename                        |
|-----------------------------|---------------------------------|
| `AzureKeyVault@2`           | `azure_key_vault.yml`           |
| `AzureWebApp@1`             | `azure_web_app.yml`             |
| `PublishPipelineArtifact@1` | `publish_pipeline_artifact.yml` |
| `FileTransform@2`           | `file_transform.yml`            |

## Requirements

Ask me for:

- **Task name and version** (e.g., `AzureCLI@2`)
- **Purpose** of the template
- **Parameters** the template should expose

Then generate a complete template file following the conventions below.

## File Structure

A task template has exactly three sections in this order, separated by a single blank line:

1. Comment block
2. Parameters block
3. Steps block

## Comment Block

The comment block is the **sole documentation** for task templates. It must include all five
subsections in order: header, Purpose, Parameters, Example Usage, Notes.

```yaml
# Azure DevOps Task: [TaskName]@[Version]
#
# Purpose:
#   [Clear, concise description of what the template does — typically two lines]
#
# Parameters:
#   - [Name] ([type], [required/optional]): [Description]. Default: [value]
#
# Example Usage:
#   - template: tasks/[filename].yml
#     parameters:
#       [Name]: 'value'
#
# Notes:
#   - [Considerations, limitations, or gotchas]
#   - See: [link to Microsoft task reference documentation]
```

### Comment block conventions

- **Purpose** — one to two lines describing what the template wraps and why it exists.
- **Parameters** — one line per parameter in the format:
  `- Name (type, required/optional): Description. Default: value`
  - Omit the `Default:` suffix for required parameters (those with no default).
  - For enumeration parameters, append `Values: a, b, c.` to the description.
  - Use the exact type name from the YAML definition (`string`, `boolean`, `number`, `object`,
    `stepList`).
  - A parameter is **required** when it has no `default:` in the YAML definition.
  - A parameter is **optional** when it has a `default:` value.
  - A parameter that is **conditionally required** (e.g., only needed when another parameter is set) should be marked `optional` with a note in its description (e.g., "required when deploying to a slot").
- **Example Usage** — provide at least one minimal example that includes all required parameters.
  If the template has distinct usage patterns (e.g., filePath vs inline), add a second example
  showing the alternative. When there are three or more examples, add a short `# Description`
  comment label above each additional example. Examples must be valid YAML that a consumer can
  copy.
- **Notes** — include a `See:` link to the Microsoft task reference docs when available.

## Parameters Block

Every parameter must have `name`, `type`, and `displayName`. Follow these conventions:

### Required parameters (no default)

```yaml
  - name: ParamName
    type: string
    # NO default - Consumer must provide this
    displayName: 'Short description (required)'
```

- Add the comment `# NO default - Consumer must provide this` on the line where `default:` would
  normally appear.
- Include `(required)` at the end of the `displayName` value.

### Optional parameters (with default)

```yaml
  - name: ParamName
    type: string
    default: 'value'
    displayName: 'Short description'
```

- Provide a sensible default that matches the underlying task's own default where possible.

### Enumeration parameters

```yaml
  - name: ParamName
    type: string
    default: 'option1'
    values:
      - option1
      - option2
    displayName: 'Short description'
```

Required enumerations omit the `default:` and use the `# NO default` comment instead:

```yaml
  - name: ParamName
    type: string
    # NO default - Consumer must provide this
    values:
      - option1
      - option2
    displayName: 'Short description (required)'
```

- Use `values:` to constrain the allowed values. List each value on its own line.
- Compact `values: [ a, b ]` syntax is also acceptable for very short lists (two to three items).

### Parameter ordering

1. Standard Azure DevOps task parameters that appear across many templates first (e.g.,
   `TaskEnvironmentVariables`, `Condition`, `WorkingDirectory`).
2. Task-specific required parameters.
3. Task-specific optional parameters.
4. Use section comments (`# Section Name`) to group related parameters when there are many.

### Parameter property ordering

Properties within each parameter must appear in this order:

1. `name`
2. `type`
3. `default` (or the `# NO default` comment)
4. `values` (when applicable)
5. `displayName`

Separate each parameter definition with a blank line.

## Steps Block

- Use `- task: TaskName@Version` to invoke the Azure DevOps task.
- Set a descriptive `displayName` on the task step that includes relevant parameter values using
  `${{ parameters.ParamName }}` expressions for context (e.g.,
  `'Download artifact: ${{ parameters.ArtifactName }}'`).
- String inputs should be quoted: `'${{ parameters.ParamName }}'`.
- Boolean and number inputs should be unquoted: `${{ parameters.ParamName }}`.

### Conditional inputs

Use compile-time `${{ if }}` expressions to include optional inputs only when the consumer
provides them:

- **Optional strings** — omit when empty:
  `${{ if ne(parameters.X, '') }}:`
- **Boolean-gated groups** — include a block of related inputs when a flag is set:
  ```yaml
  ${{ if eq(parameters.Flag, true) }}:
    inputA: '${{ parameters.A }}'
    inputB: '${{ parameters.B }}'
  ```
- Inputs that always have a meaningful value (including when using the default) do not need a
  conditional and should be passed unconditionally.

## Formatting

All files must match `.editorconfig`:

- 2-space indentation, no tabs
- LF line endings
- No trailing whitespace
- File ends with exactly one newline (no trailing blank lines)
