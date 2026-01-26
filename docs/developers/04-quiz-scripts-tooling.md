# Scripts & Tooling Quiz

Check your knowledge of scripting and tooling standards for this repository.

---

### 1. What scripting languages are preferred and which are discouraged or prohibited?

PowerShell is the standard scripting language for this repository and should be used wherever possible, regardless of platform. Bash is discouraged and should only be used for rare, complex file operations on Linux that cannot be achieved with PowerShell. Batch files are prohibited. PowerShell is cross-platform and can invoke underlying system commands on both Windows and Linux.

### 2. When should you use a script versus a built-in Azure DevOps task?

Use a script when the required logic is too complex for a built-in task or compile-time expressions, when the operation is runtime-specific, or when the task is too niche for a built-in solution. For example, `terraform_export_outputs.ps1` was created to make Terraform outputs available across jobs, as the built-in tasks only expose outputs to the current job.

### 3. What are the best practices for handling file paths and environment differences in scripts?

Always base paths on standard Azure DevOps variables such as `$(Pipeline.Workspace)`, `$(Build.SourceBranchName)`, and `$(Build.Repository.Name)`. When checking out repositories, specify the repository name as the path, and keep files in the correct directories for clarity and consistency.

### 4. What tools and extensions are recommended for developing and testing templates?

Use a YAML extension for your IDE to ensure correct loading and validation of YAML files. Extensions such as RainbowBrackets are recommended for improved readability. For Rider, VSCode, or Visual Studio, ensure you have syntax highlighting and linting enabled for YAML.

### 5. How should you add or update code snippets for IDEs like Rider, VSCode, or Visual Studio?

In Rider, use Live Templates to create reusable YAML pipeline elements (e.g., abbreviations for `${{ parameters. }}` or `${{ variables. }}`). There is currently no maintained document of shared snippets, but this is planned for the future and should be referenced in the documentation when available.

### 6. What repository-specific scripts or tools should contributors be aware of?

Currently, the main script is for updating the minimum Terraform version used on build agents. More tooling may be added in the future as needs arise. Contributors should check the `scripts/` directory for available utilities.

### 7. What are the best practices for testing scripts before committing?

There are no local testing tools available; validation is typically done by downloading the YAML from Azure DevOps and reviewing it, with AI assistance as a secondary check. Logging and clear error messages in scripts are important for troubleshooting.

---

*Consult the scripts and tooling documentation for answers. If you have suggestions for new tools, extensions, or best practices, please contribute them to the documentation.*

---

**Further Questions for Improvement:**

1. Would you consider adding a section to the documentation listing all standard environment variables and their recommended usage?
2. Are there any plans to introduce automated linting or formatting for scripts and YAML files in the repository?
3. Would you find value in a shared repository or markdown file for code snippets and Live Templates for the team?
4. Are there any additional tools or extensions you have found useful for scripting or YAML editing that should be recommended?
5. How do you handle secrets or sensitive information in scripts to ensure security and compliance?
