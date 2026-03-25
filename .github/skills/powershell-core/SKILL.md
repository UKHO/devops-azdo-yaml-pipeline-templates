---
name: powershell-core
description: >
  Expert guide for generating idiomatic, cross-platform PowerShell Core (pwsh) code.
  Use this skill whenever the user asks to write, generate, scaffold, or improve
  PowerShell scripts, functions, modules, or cmdlets. Also trigger when the user
  mentions pwsh, .ps1 files, PowerShell pipelines, cmdlets, or wants to automate
  tasks using PowerShell. Covers best practices for error handling, output formatting,
  parameter design, modules, and cross-platform compatibility (Windows, macOS, Linux).
license: MIT
---

# PowerShell Core Code Generation

This skill teaches Copilot to generate clean, idiomatic, production-quality
PowerShell Core (pwsh) code that is cross-platform, well-structured, and follows
community best practices.

---

## Core Principles

1. **Always target PowerShell Core** (`pwsh`, version 7+). Never use Windows-only
   APIs, `$PSVersionTable.PSVersion` guards are fine for compatibility notes but
   the generated code must run on Windows, macOS, and Linux by default.
2. **Use approved verbs** for function names (`Get-`, `Set-`, `New-`, `Remove-`,
   `Invoke-`, `Start-`, `Stop-`, `Write-`, etc.). Run `Get-Verb` mentally before
   naming a function.
3. **Always include `[CmdletBinding()]`** on advanced functions and use `param()`
   blocks with typed, attributed parameters.
4. **Prefer pipeline-friendly design**: functions should accept pipeline input where
   it makes sense (`ValueFromPipeline`, `ValueFromPipelineByPropertyName`).
5. **Never use `Write-Host` for data output**. Use `Write-Output`, `Write-Verbose`,
   `Write-Warning`, `Write-Error` for appropriate streams.

---

## File & Module Structure

```
my-module/
├── my-module.psd1        # Module manifest
├── my-module.psm1        # Root module (dot-sources private/public)
├── Public/               # Exported functions (one file per function)
│   └── Get-Something.ps1
├── Private/              # Internal helpers
│   └── Invoke-Helper.ps1
└── Tests/                # Pester tests
    └── Get-Something.Tests.ps1
```

- Each exported function lives in its own `.ps1` file named after the function.
- The `.psm1` dot-sources all files, e.g.:
  ```powershell
  Get-ChildItem "$PSScriptRoot/Private/*.ps1" | ForEach-Object { . $_.FullName }
  Get-ChildItem "$PSScriptRoot/Public/*.ps1"  | ForEach-Object { . $_.FullName }
  ```
- The `.psd1` manifest uses `FunctionsToExport` to explicitly list public functions.

---

## Function Template

Always generate functions using this structure:

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        One-line description.

    .DESCRIPTION
        Full description of what the function does.

    .PARAMETER ParameterName
        Description of the parameter.

    .EXAMPLE
        Verb-Noun -ParameterName 'value'
        Description of what this example does.

    .OUTPUTS
        [TypeName] Description of what is returned.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $ParameterName,

        [Parameter()]
        [switch] $Force
    )

    begin {
        # One-time setup
    }

    process {
        # Per-object pipeline logic
        if ($PSCmdlet.ShouldProcess($ParameterName, 'Action description')) {
            try {
                # Main logic
            }
            catch {
                Write-Error -Message "Failed to do X: $_" -ErrorAction Stop
            }
        }
    }

    end {
        # Cleanup
    }
}
```

---

## Parameter Design Rules

| Scenario                          | Pattern                                        |
|-----------------------------------|------------------------------------------------|
| Required input                    | `[Parameter(Mandatory)]`                       |
| Pipeline input (by value)         | `[Parameter(ValueFromPipeline)]`               |
| Pipeline input (by property name) | `[Parameter(ValueFromPipelineByPropertyName)]` |
| Boolean flag                      | `[switch]` — never `[bool]` for switches       |
| Validated strings                 | `[ValidateSet('Option1','Option2')]`           |
| File paths                        | `[ValidateScript({ Test-Path $_ })]`           |
| Credential                        | `[System.Management.Automation.PSCredential]`  |
| Secret / password                 | `[System.Security.SecureString]`               |

- Always give parameters `[Parameter()]` even if no attributes are set — it signals intent.
- Use `$PSDefaultParameterValues` patterns in examples, not hardcoded defaults for env-specific values.

---

## Error Handling

```powershell
# Terminating errors — use when the function cannot continue
throw "Descriptive message"
# or
Write-Error "Message" -ErrorAction Stop

# Non-terminating errors — use for per-item failures in a pipeline
Write-Error "Failed to process '$item': $_"

# Prefer try/catch/finally over $? checks
try {
    $result = Invoke-Something -ErrorAction Stop
}
catch [System.IO.FileNotFoundException] {
    Write-Error "File not found: $_"
}
catch {
    Write-Error "Unexpected error: $_"
    throw
}
finally {
    # Cleanup always runs
}
```

- Set `-ErrorAction Stop` on cmdlets inside `try` blocks so exceptions are catchable.
- Use typed `catch` blocks when the exception type is known.

---

## Output & Formatting

- **Return objects, not formatted strings.** Let PowerShell's formatting system handle display.
- Use `[PSCustomObject]` for structured output:
  ```powershell
  [PSCustomObject]@{
      Name   = $name
      Status = $status
      Path   = $path
  }
  ```
- Use `Select-Object` with `[ordered]` hashtables or `PSCustomObject` to control property order.
- Add `Add-Member -MemberType NoteProperty` or `Update-TypeData` for richer type output.
- Use `Write-Verbose` for progress/debug info, **not** `Write-Output`.

---

## Cross-Platform Path Handling

```powershell
# Good — works everywhere
$configPath = Join-Path $env:HOME '.config' 'myapp' 'settings.json'

# Good — resolves home dir cross-platform
$home = [System.Environment]::GetFolderPath('UserProfile')

# Avoid hard-coded separators
# Bad:  "C:\Users\$env:USERNAME\Documents"
# Good: Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) 'file.txt'

# Check OS when truly needed
if ($IsWindows) { ... }
elseif ($IsMacOS) { ... }
elseif ($IsLinux) { ... }
```

---

## Splatting

Always use splatting for cmdlets with 3+ parameters:

```powershell
# Good
$invokeParams = @{
    Uri         = 'https://api.example.com/data'
    Method      = 'POST'
    Body        = $body | ConvertTo-Json
    ContentType = 'application/json'
    Headers     = $headers
}
Invoke-RestMethod @invokeParams

# Bad
Invoke-RestMethod -Uri 'https://...' -Method 'POST' -Body ($body | ConvertTo-Json) -ContentType 'application/json' -Headers $headers
```

---

## Common Patterns

### Read/Write Configuration (JSON)
```powershell
# Read
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Write (preserves existing, updates key)
$config.MySetting = 'NewValue'
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
```

### REST API calls
```powershell
function Invoke-MyApi {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [string] $Endpoint,
        [Parameter(Mandatory)] [string] $Token
    )
    $headers = @{ Authorization = "Bearer $Token" }
    Invoke-RestMethod -Uri $Endpoint -Headers $headers -Method Get
}
```

### Parallel processing (PS 7+)
```powershell
$items | ForEach-Object -Parallel {
    # $_ is the current item
    # Use $using: to pass outer variables
    $config = $using:config
    Do-Work -Item $_ -Config $config
} -ThrottleLimit 10
```

### Retry logic
```powershell
function Invoke-WithRetry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [scriptblock] $ScriptBlock,
        [int] $MaxAttempts = 3,
        [int] $DelaySeconds = 2
    )
    $attempt = 0
    do {
        $attempt++
        try { return & $ScriptBlock }
        catch {
            if ($attempt -ge $MaxAttempts) { throw }
            Write-Warning "Attempt $attempt failed. Retrying in ${DelaySeconds}s..."
            Start-Sleep -Seconds $DelaySeconds
        }
    } while ($true)
}
```

---

## What NOT to Generate

- **No `Write-Host`** for data (only use for intentional console-only output like progress UIs).
- **No `$_` in `catch` blocks without `$Error[0]`** — prefer `$_` inside the catch scope only.
- **No positional parameter usage** in generated examples — always use named parameters for clarity.
- **No `Invoke-Expression`** — it is a security risk.
- **No untyped parameters** for public functions — always add a type constraint.
- **No global variable mutation** (`$global:`) — prefer returning values or using `$script:` in modules.

---

## Quick Reference: Key Automatic Variables

| Variable                             | Meaning                              |
|--------------------------------------|--------------------------------------|
| `$_` / `$PSItem`                     | Current pipeline object              |
| `$PSScriptRoot`                      | Directory of the current script      |
| `$PSBoundParameters`                 | Parameters actually passed by caller |
| `$MyInvocation`                      | Info about the current command       |
| `$IsWindows`, `$IsMacOS`, `$IsLinux` | OS detection (PS 6+)                 |
| `$ErrorActionPreference`             | Default error action for the scope   |
