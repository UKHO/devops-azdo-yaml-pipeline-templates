# Advanced Topics & Architecture Quiz

Challenge your understanding of advanced pipeline concepts and repository architecture.

---

### 1. What are pipeline decorators and when should they be used?

Pipeline decorators are a feature in Azure DevOps that allow you to inject steps, jobs, or stages into pipelines automatically, without modifying the original pipeline YAML. They are useful for enforcing organization-wide standards, such as adding compliance checks or telemetry, across multiple pipelines. While decorators are not currently used in this repository, it is important to be aware of them for future extensibility. For more details, refer to the dedicated documentation file on pipeline decorators in this repository.

### 2. What is the purpose of architectural decision records (ADRs) in this repository?

Architectural Decision Records (ADRs) are used to document important decisions about the repository’s architecture, tooling, and processes. Each ADR is a single, numbered file (e.g., 001-title.md) stored in an `adr/` folder, and includes metadata such as date, status, context, and consequences. ADRs are never edited after creation; if a decision changes, a new ADR supersedes the previous one. Both major and significant process-related decisions should be captured. A template and guide for ADRs should be provided in the repository to help contributors know when and how to create them. When a PR is related to an ADR, it should reference the relevant ADR in its description for traceability.

### 3. How do architectural decisions impact template design and usage?

Architectural decisions directly shape how templates are structured, composed, and consumed. For example, the decision to support both a "set menu" (predefined pipelines) and a "salad bar" (modular jobs and tasks) approach led to a flexible repository structure that supports both ready-to-use and customizable pipelines. Architectural decisions should be documented in ADRs, referenced from the README or an ADR index, and reviewed by the chapter lead and subject matter experts. When a decision introduces breaking changes, it should be clearly communicated and managed according to the repository’s versioning and documentation standards.

### 4. What was the original design intent for this repository?

The original design intent was to provide a flexible, reusable set of Azure DevOps pipeline templates that could be used out-of-the-box (the "set menu") or customized by consumers (the "salad bar"). Initially, the goal was to avoid scripting, but practical limitations led to the adoption of PowerShell for scenarios that could not be handled with YAML expressions alone. The repository aims to offer recommendations and best practices, while allowing consumers the freedom to extend or adapt templates as needed. Lessons learned include the importance of extensibility and the need to document platform or tool limitations.

### 5. How should advanced features be documented for future maintainers?

Advanced features, such as parameter objects and schema validation, should be thoroughly documented to support future maintainers. For tasks and jobs, documentation should be included as YAML comments at the top of each file, describing parameters, required/optional fields, and usage examples. For higher-level objects and schemas, documentation should be provided in Markdown files within the `docs/definitions` or `schemas` folders. Schema validation logic should be clear, with required fields enforced and optional fields validated only if present. As patterns emerge, usage examples and troubleshooting tips should be added to documentation to aid maintainers and contributors.

---

*Consult the advanced topics and architecture documentation for answers.*
