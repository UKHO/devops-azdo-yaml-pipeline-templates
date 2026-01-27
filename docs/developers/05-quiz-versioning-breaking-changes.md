# Versioning & Breaking Changes Quiz

Test your understanding of versioning and managing breaking changes in pipeline templates.

---

### 1. What constitutes a breaking change in a template?

A breaking change in a template is any modification that can cause existing consumers of the template to fail or require them to update their usage. The main types of breaking changes include:
- Adding new required parameters to templates (existing consumers will break if they do not provide these).
- Renaming, removing, or changing the type of parameters.
- Modifying the output structure or expected results.
- Removing or changing steps, jobs, or tasks in a way that affects consumers.
- Changing default values in a way that impacts downstream usage.
- Renaming jobs or tasks (consumers may depend on these names for variable access).
- Rearranging jobs or steps, which can affect execution order and dependencies.
- Changing required resources, such as upgrading the version of a tool (e.g., Terraform) used by the template, especially if the new version introduces breaking changes.
For a full list, refer to the 'how-to-version.md' guide.

### 2. What is the process for handling breaking changes in this repository?

The process for handling breaking changes involves several careful steps:
- First, thoroughly evaluate whether the breaking change is truly necessary. Consider what went wrong with the original design and whether the proposed change is the best long-term solution.
- If a breaking change is required, increment the major version of the template to signal to consumers that incompatible changes have been introduced.
- Provide clear, well-written documentation to help users migrate from the old version to the new one. This should include a migration guide outlining the steps needed to upgrade.
- Note: Currently, there is no dedicated location for migration guides, but contributors should be prepared to update the directory structure to accommodate this documentation as needed.
- Breaking changes should be made with caution, as they can be disruptive and are not easily adopted by all consumers.

### 3. How should version numbers be incremented for breaking vs. non-breaking changes?

Version numbers should follow Semantic Versioning (SemVer) as outlined in the 'how-to-version.md' guide:
- Increment the **major** version for breaking changes (incompatible API/template changes).
- Increment the **minor** version for new features that are backward compatible (e.g., adding new optional parameters or new templates).
- Increment the **patch** version for backward-compatible bug fixes or small improvements.
- If the flow or structure of a template changes in a way that breaks existing usage, this is also a breaking change and requires a major version bump.

### 4. What are examples of changes that seem minor but are actually breaking?

Some changes may appear minor but can break consumers' pipelines:
- Renaming a task or job: Consumers may depend on specific names to access variables or outputs. For example, if a job in the Terraform deploy template is renamed, any pipeline referencing outputs by the old name will break.
- Rearranging jobs or steps: Changing the order can affect dependencies and the expected flow, potentially breaking consumers who rely on the previous structure.
- Changing required resources: For example, upgrading the version of a tool (like Terraform) used by the template. If the new version introduces breaking changes, consumers may need to update their pipelines accordingly.

### 5. Where should breaking changes be documented?

Breaking changes must be thoroughly documented to help consumers migrate and understand the impact:
- Increment the major version number in the template.
- Include a migration guide that explains how to upgrade from the previous version to the new one. When a dedicated location for migration guides is established, place the documentation there.
- Update the changelog to record the breaking change and its details.
- Add inline documentation and comments in the template files themselves to highlight the change and any required actions.
- Ensure all relevant documentation is updated and proper testing is performed to validate the changes.

---

*Refer to the versioning and breaking changes guide for more information.*
