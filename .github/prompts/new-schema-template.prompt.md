---
description: 'Create a new schema validation template in schemas/'
mode: 'edit'
---

Create a new schema validation template in the `schemas/` directory.

## Requirements

Ask me for:

- **Object name** — the parameter name to validate (e.g., `DeployConfig`)
- **Properties** — the required and optional properties of the object, with their types
- **Consuming template** — which job or stage template will call the schema

Then generate the schema template following the conventions below.

## File Structure

A schema template has exactly three sections in this order:

1. Comment block (brief — detailed docs live in `docs/definition_docs/`)
2. Parameters block
3. Jobs block (containing only `${{ if }}` compile-time validation rules)

### Comment block

```yaml
# Schema Template: {Object Name}
# Validates {description} objects used by {context}.
# See: docs/definition_docs/{pipeline_name}/{object_name}.md
```

Keep it to exactly three lines. The `See:` link points to the definition doc where the full
property documentation lives (create with the `new-definition-documentation` prompt).

### Parameters block

Schema templates always receive:

1. The object to validate — `type: object`, required, with a `displayName` linking to the
   definition doc
2. A context identifier (typically `EnvironmentName`) — `type: string`, required, used in
   error messages to identify which instance failed validation

```yaml
parameters:
  - name: {ObjectName}
    type: object
    # NO default - Consumer must provide this
    displayName: '{Description} (see docs/definition_docs/{pipeline}/{object}.md)'

  - name: EnvironmentName
    type: string
    # NO default - Consumer must provide this
    displayName: 'The environment name used in error messages'
```

### Jobs block

The `jobs:` block contains **only** compile-time `${{ if }}` validation rules. It never runs
actual jobs — the rules either pass silently or produce a compile-time error that fails the
pipeline before it starts.

## Validation patterns

Use these patterns to build validation rules. The error message convention is:

```
"'${{ parameters.EnvironmentName }}' environment error: {PropertyPath} {description}.": "Error"
```

### Required string property

Check that the property exists and is not empty:

```yaml
- ${{ if or(not(parameters.Config.PropertyName), eq(parameters.Config.PropertyName, '')) }}:
  - "'${{ parameters.EnvironmentName }}' environment error: PropertyName is not properly defined and is a required field.": "Error"
```

### Required enum property

Check that the property exists, is not empty, and is one of the allowed values:

```yaml
- ${{ if or(not(parameters.Config.Mode), eq(parameters.Config.Mode, ''), notIn(parameters.Config.Mode, 'ValueA', 'ValueB', 'ValueC')) }}:
  - "'${{ parameters.EnvironmentName }}' environment error: Mode is not properly defined and is a required field.": "Error"
```

### All-or-nothing group

When a group of properties are all optional, but if any one is set then all must be set:

```yaml
- ${{ if or(parameters.Config.Group.PropA, parameters.Config.Group.PropB) }}:
  # At least one property is set, so all must be set
  - ${{ if or(not(parameters.Config.Group.PropA), eq(parameters.Config.Group.PropA, '')) }}:
    - "'${{ parameters.EnvironmentName }}' environment error: Group.PropA is required when any Group configuration is provided.": "Error"
  - ${{ if or(not(parameters.Config.Group.PropB), eq(parameters.Config.Group.PropB, '')) }}:
    - "'${{ parameters.EnvironmentName }}' environment error: Group.PropB is required when any Group configuration is provided.": "Error"
```

### Object type validation

Check that an optional property is an object (key/value pairs) when provided:

```yaml
- ${{ if parameters.Config.Mappings }}:
  - ${{ if not(contains(convertToJson(parameters.Config.Mappings), '{')) }}:
    - "'${{ parameters.EnvironmentName }}' environment error: Mappings is not correct. Must be an object of key/value pairs.": "Error"
  - ${{ else }}:
    - ${{ each mapping in parameters.Config.Mappings }}:
      - ${{ if or(not(mapping.Key), not(mapping.Value), eq(mapping.Key, ''), eq(mapping.Value, '')) }}:
        - "'${{ parameters.EnvironmentName }}' environment error: Mappings is not correct. Must be an object of key/value pairs.": "Error"
```

### List-of-strings validation

Check that an optional property is a list of plain strings when provided:

```yaml
- ${{ if parameters.Config.Items }}:
  - ${{ if not(contains(convertToJson(parameters.Config.Items), '[')) }}:
    - "'${{ parameters.EnvironmentName }}' environment error: Items is not correct. Must be a list of string values.": "Error"
  - ${{ else }}:
    - ${{ each item in parameters.Config.Items }}:
      - ${{ if or(contains(convertToJson(item), '['), contains(convertToJson(item), '{')) }}:
        - "'${{ parameters.EnvironmentName }}' environment error: Items item '${{ replace(convertToJson(item), '\n', ' ') }}' is not a string. Must be a list of string values.": "Error"
```

## Rule ordering

1. **Required properties** — validate all required fields first, grouped logically (top-level
   properties, then nested objects)
2. **Optional properties** — add a `# OPTIONAL PARAMETERS` comment, then validate optional
   fields that have structural constraints

## Consuming the schema

The schema is called as a job template from the consuming job file:

```yaml
jobs:
  - template: ../schemas/{schema_name}.yml
    parameters:
      {ObjectName}: ${{ parameters.{ObjectName} }}
      EnvironmentName: ${{ parameters.EnvironmentName }}

  - deployment: ActualDeploymentJob
    # ...
```

The schema template must be listed **before** the actual job so that validation failures prevent
the pipeline from running.

## Formatting

All files must match `.editorconfig`:

- 2-space indentation, no tabs
- UTF-8 without BOM
- LF line endings
- No trailing whitespace
- File ends with exactly one newline (no trailing blank lines)

