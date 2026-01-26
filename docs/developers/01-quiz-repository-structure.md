# Repository Structure & Organisation Quiz

Test your understanding of the repository structure and organisation for Azure DevOps YAML pipeline templates.

---

### 1. Why is the repository broken down into multiple folders? What is the purpose of each main folder (e.g., tasks/, jobs/, stages/, pipelines/, scripts/, utils/, tools/, schemas/)?

The repository is organised into multiple folders to group templates and scripts by their function and level, improving maintainability and reusability:

- **tasks/**: Contains templates for individual Azure DevOps tasks. These templates wrap native tasks, providing a stable interface, default behaviours, and clearer parameter names.
- **jobs/**: Holds job-level templates, which are self-contained and reusable. Jobs often include parameter validation and may use schemas for complex objects. Well-built jobs are easy to combine for different scenarios (e.g., `terraform-deploy`).
- **stages/**: Includes stage templates, which group jobs to achieve specific pipeline goals. Stages typically represent environments or major pipeline milestones.
- **pipelines/**: Assembles stages into complete pipelines, managing variables and overall flow. Pipelines act as the entry point for most users.
- **scripts/**: Stores PowerShell or Bash scripts required for tasks not natively supported by Azure DevOps. Scripts should be well-written and include logging for diagnostics.
- **utils/**: Contains miscellaneous YAML templates that support other templates. This folder is for shared YAML pieces and may be renamed in the future as its purpose evolves.
- **tools/**: Houses scripts and utilities for repository maintenance and automation.
- **schemas/**: Provides validation templates for complex objects passed in pipelines. While the schema concept is not fully established, these files help with compile-time validation and may be renamed as the approach matures.

### 2. When should you create a new folder in the repository? What guidelines should you follow?

New folders should be avoided unless absolutely necessary. The existing structure is designed to cover most needs. If a new folder seems required, discuss and review the need with the team before proceeding.

### 3. Where should you place a new template or script? What decision process should you use?

- Place scripts in the `scripts/` directory.
- Templates should be placed according to their function:
  - Task templates in `tasks/`
  - Job templates in `jobs/`
  - Stage templates in `stages/`
  - Pipeline templates in `pipelines/`
  - Schemas in `schemas/`
- For templates that combine multiple elements (e.g., a sequence of jobs), use a clear naming convention (e.g., `_job_list`) and place them in the relevant folder.
- If unsure, review existing templates for examples and consistency.

### 4. What does not need to be a template in this repository? Give examples.

- Simple Azure DevOps steps (e.g., `steps.checkout`, `steps.bash`, `steps.download`, `steps.publish`, `steps.pwsh`) do not need to be templated.
- Root pipeline elements such as `trigger` and `pr` cannot be templated.
- Only template steps or logic that benefit from abstraction, reuse, or additional validation.

### 5. Explain the "set menu vs. salad bar" approach in the context of this repository.

- **Set menu:** Ready-to-use pipelines designed for quick adoption (e.g., deploy infrastructure, web app, function app, or database). These pipelines require minimal customisation and help teams get started quickly.
- **Salad bar:** Modular, well-engineered jobs and tasks that teams can combine as needed for custom scenarios. This approach offers flexibility for advanced or unique requirements.

---

*Answers are based on current repository practices and may evolve as the repository matures. For more details, refer to the repository documentation and structure guides.*
