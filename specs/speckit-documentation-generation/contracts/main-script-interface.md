# AI Agent Documentation Generation Interface

## Note: PowerShell Script Interface Superseded

**Status**: This file contains PowerShell script interface specifications that have been superseded by the AI agent approach for template documentation generation.

**Replacement Approach**: Instead of building PowerShell script automation, an AI agent directly analyzes templates and generates comprehensive documentation files.

## AI Agent Process

The AI agent performs the equivalent functionality of the originally planned main script:

### Input Processing (replaces script parameters)

- **Repository Analysis**: AI agent automatically discovers all YAML templates in repository structure
- **Template Identification**: Identifies pipelines, stages, jobs, and tasks without configuration
- **Output Management**: Creates documentation files directly in docs/user-docs/ structure

### Documentation Generation (replaces script execution)

- **Comprehensive Analysis**: AI reads and understands each template thoroughly
- **Structured Output**: Generates markdown files with consistent format and quality
- **Index Creation**: Creates main README.md with complete navigation and hierarchy
- **Cross-Referencing**: Links templates through dependency analysis

## Original PowerShell Interface (Archived)

The following script interface was originally planned but is no longer needed due to the AI agent approach:

### Generate-TemplateDocumentation.ps1 (AI equivalent: Direct generation)

```powershell
# Original planned script - superseded by AI generation
param(
    [Parameter()]
    [string]$RepositoryRoot = (Get-Location),

    [Parameter()]
    [string]$OutputDirectory = "docs/user-docs",

    [Parameter()]
    [switch]$UpdateIndex,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [string[]]$IncludeTypes = @("Pipeline", "Stage", "Job", "Task"),

    [Parameter()]
    [string]$LogLevel = "Information"
)
```

### AI Agent Equivalent Results

AI agent provides comprehensive results without complex scripting:

```powershell
# AI agent equivalent output
@{
    Success = $true
    ProcessedTemplates = @(
        @{
            Name = "infrastructure_pipeline"
            Type = "Job"
            OutputPath = "docs/user-docs/jobs/terraform_build.md"
            Status = "Success|Failed"
            GenerationTime = [TimeSpan]
            Errors = @("error1", "error2")
        }
    )
    TotalTemplates = [int]
    SuccessCount = [int]
    FailureCount = [int]
    ExecutionTime = [TimeSpan]
    IndexUpdated = $true|$false
}
```

### Usage Examples

```powershell
# Generate documentation for all templates
.\Generate-TemplateDocumentation.ps1

# Generate only job and task documentation
.\Generate-TemplateDocumentation.ps1 -IncludeTypes @("Job", "Task")

# Force regeneration and update index
.\Generate-TemplateDocumentation.ps1 -Force -UpdateIndex

# Generate with verbose logging
.\Generate-TemplateDocumentation.ps1 -LogLevel "Debug"
```

### Exit Codes

- 0: Success - all templates processed successfully
- 1: Partial success - some templates failed but others succeeded
- 2: Failure - critical error prevented execution
- 3: Configuration error - invalid parameters or missing dependencies

### Error Handling

The script implements comprehensive error handling:

- Template parsing errors are captured and reported without stopping execution
- Individual template failures don't prevent processing of other templates
- Missing dependencies are detected and reported
- Invalid YAML syntax errors are caught and logged
- Output directory creation failures are handled gracefully

### Logging

Structured logging with configurable levels:

- Error: Critical failures that prevent template processing
- Warning: Non-critical issues that don't prevent generation
- Information: General progress and completion status
- Debug: Detailed parsing and generation steps
- Verbose: Full template content and transformation details
