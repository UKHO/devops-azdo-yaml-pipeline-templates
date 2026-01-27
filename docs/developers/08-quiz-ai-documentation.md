# AI & Documentation Quiz

Test your knowledge of AI usage and documentation standards in this repository.

---

### 1. What are the guidelines for using AI tools (like Copilot) in template development and documentation?

AI tools can be helpful for generating boilerplate code, structuring YAML, and accelerating documentation tasks. However, due to the complexity and lack of comprehensive training data for Azure DevOps YAML, AI-generated templates often require significant manual review and testing. The recommended workflow is to use AI for repetitive or well-structured tasks (such as generating parameter blocks or documentation summaries), but always validate and test the output in the Azure DevOps web interface or a local environment. For documentation, AI can efficiently generate summaries and parameter descriptions by referencing existing, well-written templates. Avoid relying solely on AI for complex template logic or undocumented features.

### 2. How should AI-generated content be reviewed and maintained?

All AI-generated content must be thoroughly reviewed by a human before being merged. This includes checking for accuracy, completeness, and adherence to repository standards. AI-generated changes should be submitted via pull requests, where they can be discussed and refined as needed. Regular maintenance and periodic reviews are recommended to ensure that AI-generated documentation and code remain up to date and relevant.

### 3. What updates are required for the copilot-instructions when repository practices change?

Whenever repository practices change, copilot-instructions should be updated to reflect new standards, breaking changes, and best practices. This includes ensuring that display names, parameter descriptions, and documentation blocks are up to date, and that all pipeline and task files include clear, consistent documentation. The copilot-instructions should serve as a single source of truth for contributors and AI tools, helping maintain high standards across the repository.

### 4. How can AI assist in keeping documentation up to date?

AI can rapidly generate and update documentation by summarizing code, extracting parameter information, and creating usage examples. This makes it easier to keep documentation current as templates evolve. By leveraging AI to automate routine documentation tasks, maintainers can focus on reviewing and refining content, ensuring accuracy and clarity. However, human oversight is essential to catch errors and ensure that documentation remains relevant and high quality.

### 5. What are the risks and benefits of using AI for documentation in this context?

Benefits of using AI for documentation include increased speed, consistency, and coverage, especially for repetitive or structured content. Risks include the potential for inaccurate, incomplete, or poorly structured documentation if the underlying templates are not well written or if AI misinterprets the code. To mitigate these risks, always review AI-generated documentation, ensure templates are well-structured, and avoid using AI to generate documentation from scratch without reference to existing standards.

---

*See the AI and documentation guidelines for more information.*
