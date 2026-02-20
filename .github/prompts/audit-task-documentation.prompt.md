---
description: 'Audit a task or utility template to ensure its in-file documentation block is complete and accurate'
mode: 'edit'
---

Audit the selected `tasks/` or `utils/` template file.

Compare the in-file comment block at the top of the file against the actual `parameters:` section
and `steps:` implementation below it. Report and fix any of the following:

1. **Missing comment block** — Add one following this format:

   ```yaml
   # Azure DevOps Task: [TaskName]@[Version]
   #
   # Purpose:
   #   [Description]
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
   #   - [Considerations]
   ```

2. **Parameter mismatch** — Every parameter in the `parameters:` block must appear in the
   comment's Parameters list with the correct type, required/optional status, and default value.
   Remove any documented parameters that no longer exist.

3. **Stale examples** — If example usage references parameters that have been renamed or removed,
   update the examples to match the current parameters.

4. **Wrong task version** — If the `steps:` section uses a different task version (e.g.,
   `PowerShell@2`) than what the comment block states, update the comment block.

5. **Missing notes** — If the template has important limitations, conditions, or gotchas that
   are not documented in the Notes section, add them.

Do not change the template's functional code — only update the comment block.

