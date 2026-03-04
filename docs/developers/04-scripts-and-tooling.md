# Scripts & Tooling

## Language Policy

| Language       | Status                                                                                 |
|----------------|----------------------------------------------------------------------------------------|
| **PowerShell** | Preferred. Use everywhere, including Linux (PowerShell is cross-platform).             |
| **Bash**       | Allowed only for rare, complex file operations on Linux that PowerShell cannot handle. |
| **Batch**      | Prohibited.                                                                            |

## When to Use a Script

Use a script when:

- The logic is too complex for a built-in task or compile-time expression.
- The operation is runtime-specific.
- No built-in task exists for the requirement.

Example: `scripts/terraform/terraform_export_outputs.ps1` makes Terraform outputs available across jobs, which built-in tasks cannot do.

## File Paths

Always base paths on standard Azure DevOps variables:

- `$(Pipeline.Workspace)`
- `$(Build.SourceBranchName)`
- `$(Build.Repository.Name)`

When checking out repositories, specify the repository name as the path.

## IDE Setup

- Use an IDE with YAML support and syntax highlighting (VS Code, JetBrains Rider, Visual Studio).
- For VS Code, install the **Azure Pipelines** extension.
- Ensure your editor respects the `.editorconfig` file (2-space indentation, no tabs).
- Extensions like **RainbowBrackets** improve readability.

## Repository Tools

Check the `tools/` and `scripts/` directories for available utilities (e.g., `Set-TerraformVersionAcrossRepository.ps1`).

---

[← Back to Developer Documentation](README.md)

