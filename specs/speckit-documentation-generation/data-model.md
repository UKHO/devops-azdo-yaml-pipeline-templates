# Data Model: Template Documentation System

**Purpose**: Define the key entities and their relationships for AI agent-driven template documentation generation.

**Date**: 2025-10-15

## Core Entities

### Template

Represents an Azure DevOps YAML template file that can be consumed by users.

**Attributes**:

- `FilePath`: Relative path to the template file (string)
- `Name`: Template name derived from filename (string)
- `Type`: Template category - Pipeline, Stage, Job, or Task (enum)
- `Purpose`: Primary functionality description (string)
- `Parameters`: Collection of Parameter entities
- `Dependencies`: Collection of template references
- `HiddenFunctionality`: Non-obvious capabilities (array of strings)

**Validation Rules**:

- FilePath must exist and be valid YAML
- Type must match directory structure (pipelines/, stages/, jobs/, tasks/)
- Name must be unique within its type category

**State Transitions**: Static entity - no state changes after parsing

### Parameter

Represents a configurable input parameter for a template.

**Attributes**:

- `Name`: Parameter identifier (string)
- `Type`: Data type (string, object, stepList, etc.)
- `Default`: Default value if not specified (any type)
- `DisplayName`: User-friendly description (string)
- `Required`: Whether parameter is mandatory (boolean)
- `ValidationRules`: Constraints on parameter values (string)

**Validation Rules**:

- Name must be valid YAML parameter identifier
- Type must be valid Azure DevOps parameter type
- DisplayName should be descriptive and user-friendly

**Relationships**: Belongs to one Template

### TemplateReference

Represents a dependency relationship between templates.

**Attributes**:

- `SourceTemplate`: Template that references another (Template entity)
- `TargetPath`: Relative path to referenced template (string)
- `Context`: Where the reference appears (step, job, stage level)
- `Purpose`: Why this template is referenced (string)

**Validation Rules**:

- TargetPath must resolve to existing template file
- Context must be valid Azure DevOps template usage location

**Relationships**: Links two Template entities in dependency relationship

### DocumentationPage

Represents the generated markdown documentation for a template.

**Attributes**:

- `Template`: Associated template entity
- `OutputPath`: Where generated documentation is saved (string)
- `Sections`: Ordered collection of documentation sections
- `LastGenerated`: Timestamp of generation (DateTime)
- `SourceVersion`: Git commit hash of source template when generated (string)

**Validation Rules**:

- OutputPath must be within docs/user-docs/ structure
- All required sections must be present
- Generated content must be valid Markdown

### DocumentationSection

Represents a section within a documentation page.

**Attributes**:

- `Title`: Section heading (string)
- `Content`: Markdown content for the section (string)
- `Order`: Display sequence within document (integer)
- `Type`: Section category (Overview, Usage, Parameters, Dependencies, Examples)

**Validation Rules**:

- Title must be valid Markdown heading
- Content must be valid Markdown syntax
- Order must be unique within document

## Entity Relationships

```
Template (1) -----> (0..*) Parameter
Template (1) -----> (0..*) TemplateReference (as source)
Template (0..*) <-- (1) TemplateReference (as target)
Template (1) -----> (1) DocumentationPage
DocumentationPage (1) -----> (1..*) DocumentationSection
```

## Data Flow

1. **Template Discovery**: AI agent scans repository directories to identify template files
2. **Template Analysis**: AI agent reads and parses YAML content to extract Parameters and TemplateReferences
3. **Dependency Resolution**: AI agent builds complete dependency graph between templates
4. **Documentation Generation**: AI agent creates comprehensive markdown documentation with structured sections
5. **Output Writing**: AI agent generates markdown files directly in docs/user-docs/ structure

## Data Volume Estimates

- **Templates**: 5 current (1 pipeline, 1 stages, 1 job, 3 tasks)
- **Parameters**: ~20-30 total across all templates (average 4-5 per template)
- **TemplateReferences**: ~10-15 dependency relationships
- **DocumentationPages**: 5 (one per template)
- **DocumentationSections**: ~30-40 (5-7 sections per page)

**Storage Requirements**: Minimal - all data processed in memory, output as static files
