# Template Development Guidelines Quiz

Assess your understanding of best practices for developing reusable pipeline templates.

---

### 1. What are the best practices for passing and validating parameters in templates?

When deciding how to pass parameters, consider whether the values are conceptually related. If so, group them into an object parameter (e.g., `InfrastructureConfig`), which can be validated using a schema template. For unrelated or simple values, use individual parameters. Required parameters should not have a default value and should be clearly marked (e.g., with a comment such as `# no default, consumer must supply this`). Validation logic for objects should be implemented in a schema template (see `schemas/infrastructure_config.yml`), and contributors should refer to real examples in the codebase for patterns. Consider maintaining a markdown file with validation examples and troubleshooting tips for contributors.

### 2. How should object parameters be structured and validated across template layers?

Each parameter should include: name, type, (optional) default, (optional) allowed values, and displayName. Keep related parameters grouped together for clarity. At each template layer (pipeline, stage, job, task), ensure parameters are passed and validated appropriately. Use schema validation for complex objects and document the rationale for object use in the template header.

### 3. What is the difference between pipeline-level and job-level variables, and when should each be used?

The difference is scope: pipeline-level variables are overridden by stage-level variables, which are in turn overridden by job-level variables. Be aware of variable precedence to avoid unexpected behaviour. Consider adding a troubleshooting section to documentation for common variable scope issues.

### 4. How do you break down a pipeline into reusable templates?

Start by extracting individual tasks into task templates. Next, group tasks into job templates, then group jobs into stage templates, and finally assemble stages into pipeline templates. Remove duplication by using compile-time expressions (e.g., `foreach` for repeated stages). Review open-source pipeline repositories for inspiration on abstraction and structure.

### 5. What are common anti-patterns and mistakes to avoid when developing templates?

- Avoid double-wrapping: do not create templates whose sole purpose is to provide predefined settings to another template (see `anti-pattern-double-wrapping.md`).
- Avoid excessive parameterisation: do not require users to pass unnecessary parameters.
- Maintain clear and consistent naming conventions.
- Keep documentation up to date and relevant.
- Maintain a living list of common mistakes and anti-patterns in the documentation for contributors to reference.

### 6. How should required and optional parameters be documented?

Task templates should have a strong documentation block at the top, clearly listing required and optional parameters, with usage examples. Job templates should focus on validation logic, while pipeline templates should be documented in user-facing markdown files. Consider adopting a standard header for all templates to improve discoverability and consistency.

---

*See the template development guide and living documentation for more details, examples, and troubleshooting tips. Contributors are encouraged to review real code examples and open-source repositories for best practices.*
