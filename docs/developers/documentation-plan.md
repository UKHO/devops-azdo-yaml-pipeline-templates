# Developer Documentation Plan

This document outlines how to organize the tasklist questions into comprehensive developer documentation.

---

## 📋 Documentation Structure Overview

Based on the questions in the tasklist, the documentation should be organized into **7 main sections**:

1. **Repository Structure & Organization**
2. **YAML Standards & Best Practices**
3. **Template Development Guidelines**
4. **Scripts & Tooling**
5. **Versioning & Breaking Changes**
6. **Development Workflow & Testing**
7. **Advanced Topics & Architecture**

---

## 1️⃣ Repository Structure & Organization

**Document Name:** `repository-structure-guide.md`

**Questions Covered:**
- Why the breakdown of folders?
- Can we add new folders?
- Where do we place new things
- What are the folders for?
- What does not need to be a template

**Content Outline:**
- Overview of folder structure (tasks/, jobs/, stages/, pipelines/, scripts/, utils/)
- Purpose of each folder with examples
- Decision tree for where to place new components
- Guidelines for creating new folders (when and why)
- What belongs in the repository vs. consuming projects
- The "set menu vs. salad bar" approach explained

**Cross-References:**
- Links to existing `docs/repository-structure.md`
- Link to anti-pattern documentation

---

## 2️⃣ YAML Standards & Best Practices

**Document Name:** `yaml-standards-and-conventions.md`

**Questions Covered:**
- How does yaml itself work?
- What is special about azdo yaml?
- Common yaml structures?
- yml vs yaml, what do we stick to?
- What is the naming convention for files?
- What is the naming convention for folders?
- What attributes need focusing on

**Content Outline:**
- YAML fundamentals (anchors, aliases, multi-line strings, data types)
- Azure DevOps YAML specifics (compile-time vs. runtime expressions, template syntax)
- Naming conventions:
  - Files: snake_case with `.yml` extension
  - Folders: snake_case
  - Parameters: camelCase
  - Variables: UPPER_CASE or camelCase (document context)
- EditorConfig rules and formatting requirements
- Common patterns and idioms used in the repository
- What makes a good parameter name or step displayName

**Cross-References:**
- Link to `.editorconfig`
- Link to official Azure DevOps YAML schema documentation
- Examples from the repository

---

## 3️⃣ Template Development Guidelines

**Document Name:** `template-development-guide.md`

**Questions Covered:**
- How to write the templates
- What are common ways of passing parameters
- What are the best ways of validating parameters
- What are the different ways of laying out object parameters?
- The object parameters and how to validate them?
- What are common validation patterns?
- How should objects be composited and unpacked through the layers?
- What does each layer do?
- What is the concerns of each layer?
- The pipeline vs jobs approach

**Content Outline:**
- Template anatomy and documentation requirements (from copilot-instructions.md)
- Parameter design:
  - Simple vs. object parameters
  - When to use each type
  - Validation techniques (type checking, allowed values, compile-time validation)
- Layering and separation of concerns:
  - Tasks: Atomic operations wrapping Azure DevOps tasks
  - Jobs: Collections of steps with specific objectives
  - Stages: Collections of jobs with deployment gates
  - Pipelines: Full orchestration templates
- Parameter passing patterns:
  - Direct parameter mapping
  - Object parameters for complex configs
  - Variable expansion patterns
- The importance of ordering variables in jobs (scope and precedence)
- Avoiding double-wrapping (link to anti-pattern doc)
- Reusability and modularity principles

**Cross-References:**
- Link to `docs/anti-pattern-double-wrapping.md`
- Link to example templates in tasks/, jobs/, stages/
- Link to schema files

---

## 4️⃣ Scripts & Tooling

**Document Name:** `scripts-and-tooling.md`

**Questions Covered:**
- What to bare in mind with scripts
- PowerShell is the preferred
- No BAT files at all
- BASH is OK but ideally build machines are powershell enabled
- Focus on relying on the tasks as much as possible
- Scripting for complex behaviour that cannot be determined at runtime
- What is the compile vs runtime thoughts?
- File system and absolute paths
- What are the common directories that would appear on a build machine?
- What tooling is available to help?
- How to add to rider/vscode/vs snippets for code
- Are there any extensions that can be used?

**Content Outline:**
- Scripting guidelines:
  - PowerShell preferred for cross-platform compatibility
  - NO BAT files
  - Bash acceptable but not preferred
  - When to use scripts vs. built-in tasks
- Compile-time vs. runtime:
  - Template expressions (`${{ }}`) evaluate at compile time
  - Macro syntax (`$()`) evaluates at runtime
  - Variable syntax differences
  - When to use each approach
- File system considerations:
  - Common directories (Pipeline.Workspace, Build.SourcesDirectory, Agent.TempDirectory)
  - Absolute vs. relative paths
  - Cross-platform path handling
- Development tooling:
  - IDE extensions (Azure Pipelines extension for VSCode)
  - YAML linters and validators
  - Creating code snippets for Rider/VSCode/VS
  - PowerShell tools (Set-TerraformVersionAcrossRepository.ps1)

**Cross-References:**
- Link to scripts/ folder
- Link to official Azure DevOps predefined variables documentation

---

## 5️⃣ Versioning & Breaking Changes

**Document Name:** `versioning-and-breaking-changes-guide.md`

**Questions Covered:**
- Version changes, how does that work?
- What are the breaking changes?
- What are changes that look innocent when we first make them but would box us in if we changed them

**Content Outline:**
- Semantic versioning recap (Major.Minor.Patch)
- Detailed breakdown of breaking changes:
  - Parameter changes (removal, renaming, type changes)
  - Default value changes
  - Output structure changes
  - Behavioral changes
- "Innocent-looking" changes that can be breaking:
  - Changing step/job/stage names that downstream relies on
  - Reordering steps that have implicit dependencies
  - Changing variable scopes
  - Modifying condition expressions
  - Changes to artifact names or paths
- Non-breaking changes examples
- Process for introducing breaking changes:
  - Documentation requirements
  - CHANGELOG updates
  - Major version bump
  - Migration guides for consumers

**Cross-References:**
- Link to existing `docs/how-to-version.md`
- Link to CHANGELOG.md
- Link to Semantic Versioning 2.0.0 spec

---

## 6️⃣ Development Workflow & Testing

**Document Name:** `development-workflow-and-testing.md`

**Questions Covered:**
- Development environment, how to config
- How to test your changes?
- When is a good time for a PR?
- Guidance on PRs
- PR Process?
- What is the branching strategy
- How to develop a pipeline and then break it down into templates?
- Whether force merging should be a thing or not

**Content Outline:**
- Development environment setup:
  - Required tools (Git, IDE, PowerShell)
  - Recommended extensions
  - EditorConfig setup
- Testing strategies:
  - Using test pipelines in tests/pipelines/
  - Creating isolated test scenarios
  - Testing breaking changes vs. non-breaking changes
  - Validating against multiple consuming scenarios
- Branching strategy:
  - Feature branches from main
  - Naming conventions
  - When to branch
- Pull Request process:
  - When to create a PR (early for feedback vs. when complete)
  - PR checklist:
    - All tests passing
    - Documentation updated
    - CHANGELOG updated
    - Version bump applied (if merging)
  - Review process and code owners
  - No force merging policy (explain why)
- Development approach:
  - Start with a working pipeline in a consumer repo
  - Identify reusable patterns
  - Extract to templates incrementally
  - Test each extraction step

**Cross-References:**
- Link to CONTRIBUTING.md
- Link to CODEOWNERS
- Link to tests/ folder
- Link to versioning guide

---

## 7️⃣ Advanced Topics & Architecture

**Document Name:** `advanced-topics.md`

**Questions Covered:**
- The pipeline vs jobs approach (Saladbar vs set menu)
- What is the importance of ordering the variables in the jobs?
- At what level should variables be used?
- What are pipeline decorators
- What are the ADRs that were taken?
- What was the original design?
- Links to online resources that will help developers

**Content Outline:**
- "Set Menu vs. Salad Bar" philosophy:
  - Set Menu: Full pipeline templates (pipelines/)
  - Salad Bar: Composable components (tasks/, jobs/, stages/)
  - When to use each approach
  - How they work together
- Variable scoping and precedence:
  - Pipeline-level variables
  - Stage-level variables
  - Job-level variables
  - Step-level variables
  - Order of evaluation and override behavior
- Pipeline decorators explained:
  - What they are
  - How they affect templates
  - Common gotchas
- Architecture Decision Records (ADRs):
  - Historical context
  - Why certain patterns were chosen
  - Original design goals
  - Evolution of the repository
- External resources:
  - Official Azure DevOps documentation
  - YAML specifications
  - Semantic Versioning
  - Community best practices

**Cross-References:**
- Link to `docs/pipeline-decorators-explained.md`
- Link to README.md for set menu/salad bar intro
- External links to Microsoft documentation

---

## 8️⃣ AI & Documentation

**Document Name:** `ai-assisted-development.md`

**Questions Covered:**
- The usage of AI, what are the guidelines, what do we need to outline, using AI to write the documentation is good
- What updates to the copilot-instructions do I need to write?
- The process of updating the user docs
- Updating other documentation

**Content Outline:**
- AI usage guidelines:
  - Appropriate use cases (documentation, template generation, testing)
  - Review requirements for AI-generated content
  - Maintaining consistency with existing patterns
  - Using GitHub Copilot effectively in this repository
- Copilot instructions maintenance:
  - When to update .github/copilot-instructions.md
  - What to include (coding standards, breaking change rules, conventions)
  - Testing Copilot behavior after updates
- Documentation process:
  - User docs (docs/user-docs/) for consumers
  - Developer docs (docs/developers/) for contributors
  - When to update which documentation
  - Documentation review and validation
  - Using AI to improve clarity and completeness

**Cross-References:**
- Link to `.github/copilot-instructions.md`
- Link to docs/user-docs/ and docs/developers/

---

## 📝 Implementation Recommendations

### Phase 1: Core Documentation (Priority)
1. **Template Development Guide** - Most frequently needed
2. **Repository Structure Guide** - Foundation for understanding
3. **Versioning & Breaking Changes Guide** - Critical for maintainability

### Phase 2: Standards & Workflow
4. **YAML Standards & Conventions** - Ensures consistency
5. **Development Workflow & Testing** - Onboarding new contributors

### Phase 3: Advanced & Supporting
6. **Scripts & Tooling** - Supporting material
7. **Advanced Topics** - Deep dives
8. **AI & Documentation** - Process documentation

### Documentation Best Practices
- **Use examples** from the actual repository wherever possible
- **Link extensively** between documents to create a web of knowledge
- **Include visual aids** (diagrams, decision trees) for complex concepts
- **Provide code snippets** with inline comments
- **Create quick reference cards** for common patterns
- **Maintain a glossary** of terms (compile-time, runtime, decorator, etc.)

### Tools to Create
- Decision tree flowchart: "Where should I put this new component?"
- Checklist template: "Pre-PR validation checklist"
- Quick reference: "Parameter validation patterns"
- Template: "New template file structure"

---

## 🔗 Documentation Cross-Reference Map

```
README.md (Entry point for users)
├── docs/user-docs/README.md (For consumers)
└── CONTRIBUTING.md (Entry point for contributors)
    ├── docs/developers/
    │   ├── repository-structure-guide.md
    │   ├── yaml-standards-and-conventions.md
    │   ├── template-development-guide.md
    │   ├── scripts-and-tooling.md
    │   ├── versioning-and-breaking-changes-guide.md
    │   ├── development-workflow-and-testing.md
    │   ├── advanced-topics.md
    │   └── ai-assisted-development.md
    ├── docs/how-to-version.md (Referenced by multiple docs)
    ├── docs/repository-structure.md (Referenced by structure guide)
    ├── docs/anti-pattern-double-wrapping.md (Referenced by template guide)
    └── docs/pipeline-decorators-explained.md (Referenced by advanced topics)
```

---

## 🎯 Next Steps

1. Review this plan and adjust priorities based on immediate needs
2. Start with Phase 1 documents
3. Create templates for consistent documentation structure
4. Gather examples from existing templates for each document
5. Review and iterate with code owners
6. Update CONTRIBUTING.md with links to new documentation

---

## Questions Not Yet Covered

All 59 questions from the tasklist have been addressed and grouped into the 8 documentation sections above.

