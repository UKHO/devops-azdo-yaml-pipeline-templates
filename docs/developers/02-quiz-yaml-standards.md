# YAML Standards & Best Practices Quiz

Test your knowledge of YAML and Azure DevOps YAML conventions for this repository.

---

### 1. What are the key differences between standard YAML and Azure DevOps YAML?

While Azure DevOps YAML is based on standard YAML, there are important limitations and differences to be aware of:

- **Anchors and aliases** are only partially supported and rarely work reliably, especially across multiple files. Avoid using them.
- **Merge keys** and **custom tags** are not supported.
- **Multi-document YAML** (using `---`) is not supported; each pipeline file must be a single document.
- Not all YAML data types are implemented (e.g., timestamp, binary).
- Complex objects are allowed, but expressions and conditions must be a single string.
- The pipeline structure is primarily a map of sequences and maps; understanding the difference is key to writing valid pipelines.

### 2. What are common YAML structures used in pipeline templates (e.g., anchors, aliases, multi-line strings)?

The most common structures are:

- **Compile-time expressions** (`${{ }}`): Used to control rendering, inject parameter values, and transform information at compile time. For example, `${{ if }}` expressions can conditionally include steps or jobs.
- **Multi-line strings**: Useful for scripts or long parameter values.
- **Sequences and maps**: The core of pipeline structure.

Refer to real, working examples in the codebase (such as `jobs/terraform_deploy.yml`) for practical usage, as only actively used patterns are documented.

### 3. What naming conventions should be followed for files and folders?

- Use **lowercase_snakecase** for all file and folder names.
- YAML files must use the `.yml` extension (not `.yaml`).
- Do not include the type in the name (e.g., use `template.yml` not `job_template.yml`). For lists, use a descriptive suffix (e.g., `template_job_list.yml`).
- Naming is currently enforced by convention, but future automation (e.g., pre-commit hooks or CI checks) is planned.

### 4. What file extension should be used for YAML files in this repository, and why?

Use `.yml` (not `.yaml`). This follows Microsoft’s default (`azure-pipelines.yml`) and maintains consistency, especially as not all YAML features are supported.

### 5. Which YAML attributes require special attention in Azure DevOps pipelines?

- **Conditions**: Incorrect conditions can cause steps or jobs not to run as expected. They are not validated at compile time, so issues may only appear at runtime.
- **Parameters**: Passing and accessing parameter values, especially with complex objects, can be tricky. Use compile-time expressions carefully.
- **Indentation**: YAML is indentation-sensitive. Use your IDE’s defaults and review carefully to avoid errors.

### 6. What are some best practices for maintainability and troubleshooting?

- Use clear line breaks, comments, and descriptive `displayName` values.
- For complex templates, keep headers concise and move detailed documentation to a Markdown file if needed.
- Consider adding a standard header to all templates for discoverability.
- A troubleshooting guide or FAQ would be valuable for common issues with parameters, conditions, and YAML structure.
- Rely on your IDE for indentation; JetBrains Rider, Visual Studio, and VSCode all have YAML support.

---

*Refer to the YAML standards and conventions documentation, and review real examples in the codebase for up-to-date patterns and best practices. Document limitations and troubleshooting tips to help new contributors avoid common pitfalls.*
