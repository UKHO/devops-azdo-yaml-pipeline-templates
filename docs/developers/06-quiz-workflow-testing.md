# Development Workflow & Testing Quiz

Evaluate your knowledge of the development workflow and testing practices for this repository.

---

### 1. What is the recommended development environment setup for working on this repository?

The recommended development environment is any IDE that supports YAML files with proper syntax highlighting. For VS Code, the Azure Pipelines extension is recommended as a baseline for syntax validation and highlighting. Contributors are encouraged to investigate and propose new linters or validation tools as the repository grows. All contributors should ensure their editor supports and is configured to follow the repository’s .editorconfig file, with 2-space indentation and no tabs as critical formatting standards.

### 2. What is the process for submitting a pull request (PR)?

Contributors should create a draft PR for initial feedback, allowing Copilot to review and provide comments. Draft PRs help reduce notification noise and facilitate early review. A simple PR checklist (ideally baked into Copilot instructions) is recommended to ensure display names, parameter descriptions, and job/stage naming are correct. While the chapter lead is the main reviewer, peer review is encouraged for knowledge sharing and quality. Automated checks (CI/CD) are planned for the future; contributors should watch for updates.

### 3. When is it appropriate to open a PR, and what should be included?

Open a PR as soon as a working template is ready for feedback, preferably as a draft. Include the YAML files with clear descriptions. It is recommended to submit code PRs first, followed by documentation PRs, and link them in the PR description for traceability. Usage examples should be updated in code PRs if they are YAML examples; otherwise, update them in documentation PRs.

### 4. How should you test your changes before submitting them?

Test changes by running the pipeline and verifying correct compilation and execution. For Terraform, use mock providers where available to test non-creative resources. Full mocking of external dependencies is not possible, but contributors should document any limitations in their PR. Contributors are encouraged to share best practices for setting up test environments as the repository matures.

### 5. What is the branching strategy for this repository?

Branch naming should be formalized: use feature/xyz for features and docs/abc for documentation. Branches must be deleted after merging. In case of conflicts, code branches take precedence. Rebasing is preferred over merging from main, and squashing is only allowed on the main branch.

---

*See the development workflow and testing documentation for details.*
