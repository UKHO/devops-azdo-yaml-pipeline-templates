# AI Agent Documentation Generation Approach

## Note: PowerShell Interfaces Superseded

**Status**: This file contains PowerShell interface specifications that have been superseded by the AI agent approach for template documentation generation.

**Replacement Approach**: Instead of building PowerShell automation infrastructure, an AI agent directly reads YAML templates and generates comprehensive documentation.

## AI Agent Capabilities

The AI agent performs the equivalent functionality of the originally planned PowerShell modules:

### Template Analysis (replaces YamlParser.psm1)

- **Direct YAML Reading**: AI agent reads and understands YAML syntax natively
- **Parameter Extraction**: Identifies all template parameters with types, defaults, and displayNames
- **Dependency Analysis**: Analyzes template references and builds dependency maps
- **Hidden Functionality Discovery**: Understands template capabilities beyond obvious parameters

### Template Documentation Generation (replaces DocGenerator.psm1)

- **Structured Documentation**: Generates consistent markdown format across all templates
- **Parameter Tables**: Creates comprehensive parameter reference tables
- **Usage Examples**: Develops practical examples based on template analysis
- **Cross-References**: Links related templates through dependency analysis

## Original PowerShell Interface (Archived)

The following interfaces were originally planned but are no longer needed due to the AI agent approach:

### Get-TemplateMetadata (AI equivalent: Direct template analysis)

```powershell
# Original planned function - superseded by AI analysis
function Get-TemplateMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$YamlContent
    )

    # Returns: array of PSCustomObject with properties:
    # - Name: string
    # - Type: string
    # - Default: any
    # - DisplayName: string
    # - Required: boolean
}
```

### Get-TemplateDependencies

Identifies template references within YAML content.

```powershell
function Get-TemplateDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$YamlContent
    )

    # Returns: array of PSCustomObject with properties:
    # - TargetPath: string
    # - Context: string (step|job|stage)
    # - Purpose: string
}
```

## DocGenerator.psm1

### New-TemplateDocumentation

Generates complete documentation for a template.

```powershell
function New-TemplateDocumentation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$TemplateMetadata,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [string]$TemplateDocumentPath = "templates/template-doc.md"
    )

    # Returns: PSCustomObject with properties:
    # - Success: boolean
    # - OutputPath: string
    # - GeneratedSections: array of section names
    # - Errors: array of error messages
}
```

### New-ParameterTable

Creates markdown table for template parameters.

```powershell
function New-ParameterTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Parameters
    )

    # Returns: string (markdown table)
}
```

### New-DependencySection

Creates dependency documentation section.

```powershell
function New-DependencySection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Dependencies,

        [Parameter(Mandatory)]
        [string]$TemplateBasePath
    )

    # Returns: string (markdown content)
}
```

## TemplateAnalyzer.psm1

### Get-AllTemplates

Discovers all templates in repository structure.

```powershell
function Get-AllTemplates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RepositoryRoot
    )

    # Returns: array of template file paths grouped by type
    # PSCustomObject with properties:
    # - Pipelines: array of file paths
    # - Stages: array of file paths
    # - Jobs: array of file paths
    # - Tasks: array of file paths
}
```

### Test-TemplateValidity

Validates template YAML syntax and structure.

```powershell
function Test-TemplateValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplatePath
    )

    # Returns: PSCustomObject with properties:
    # - IsValid: boolean
    # - ValidationErrors: array of error messages
    # - Warnings: array of warning messages
}
```

### Get-HiddenFunctionality

Analyzes template to identify non-obvious capabilities.

```powershell
function Get-HiddenFunctionality {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$YamlContent,

        [Parameter(Mandatory)]
        [string]$TemplateType
    )

    # Returns: array of strings describing hidden functionality
}
```
