# Tasklist Grouping Summary

This document summarizes how the developer tasklist questions are grouped into documentation sections, based on the analysis and documentation plan. Each group corresponds to a major guide or topic area for developer documentation.

---

## Grouping Overview

The 59 tasklist questions have been organized into the following main documentation sections:

1. **Repository Structure & Organization**
2. **YAML Standards & Best Practices**
3. **Template Development Guidelines**
4. **Scripts & Tooling**
5. **Versioning & Breaking Changes**
6. **Development Workflow & Testing**
7. **Advanced Topics & Architecture**
8. **AI & Documentation**

---

## Group Details

### 1. Repository Structure & Organization
- Why the breakdown of folders?
- Can we add new folders?
- Where do we place new things
- What are the folders for?
- What does not need to be a template
- Saladbar vs set menu

### 2. YAML Standards & Best Practices
- How does yaml itself work?
- What is special about azdo yaml?
- Common yaml structures?
- yml vs yaml, what do we stick to?
- What is the naming convention for files?
- What is the naming convention for folders?
- What attributes need focusing on

### 3. Template Development Guidelines
- How to write the templates
- What are common ways of passing parameters
- How to pass parameters correctly
- What are the best ways of validating parameters
- What are the different ways of laying out object parameters?
- The object parameters and how to validate them?
- What are common validation patterms?
- How should objects be composited and unpacked through the layers?
- The pipeline vs jobs approach
- The usage of variables in jobs
- At what level should variables be used?
- The importance of ordering the variables in the jobs?
- The process of updating the user docs
- Updating other documentation
- What does each layer do?
- What is the concerns of each layer?
- How to develop a pipeline and then break it down into templates?

### 4. Scripts & Tooling
- What to bare in mind with scripts
- PowerShell is the perferred
- No BAT files at all
- BASH is OK but ideally build machines are powershell enabled
- Focus on relying on the tasks as much as possible
- Scripting for complex behaviour that cannot be determined at runtime
- What is the compile vs runtime thoughts?
- File system and absolute paths
- What are the common directories that would appear on a build machine?
- How to add to rider/vscode/vs snippets for code
- Are there any extensions that can be used?
- What tooling is available to help?
- Links to online resources that will help developers

### 5. Versioning & Breaking Changes
- Version changes, how does that work?
- What are the breaking changes?
- What are changes that look innocent when we first make them but would box us in if we changed them

### 6. Development Workflow & Testing
- Development environment, how to config
- Guidance on PRs
- PR Process?
- When is a good time for a PR?
- How to test your changes?
- What is the branching strategy

### 7. Advanced Topics & Architecture
- What are pipeline decorators
- What was the original design?
- What is the ADRs that were taken?

### 8. AI & Documentation
- The usage of AI, what are the guidelines, what do we need to outline, using AI to write the documentation is good
- What updates to the copilot-instructions do I need to write?

---

## Notes
- Some questions appear in multiple sections; the grouping above reflects their primary context.
- This summary is based on the analysis in `analysis-summary.md` and the structure in `documentation-plan.md`.
- Each section will be developed into a standalone guide as outlined in the documentation plan.
