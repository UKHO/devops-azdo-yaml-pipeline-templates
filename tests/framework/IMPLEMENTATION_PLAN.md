# Testing Framework Implementation Plan

**Date:** April 28, 2026  
**Purpose:** Detailed implementation plan for adding directory-based compilation testing to the framework with refined architecture.

---

## Executive Summary

This document outlines the implementation strategy for adding `Run-DirectoryCompileTests` functionality to support simplified batch testing of multiple YAML files in a directory. The design prioritizes:

1. **Self-contained test runners** – Each test runner (`ParameterisedTestRunner`, `DirectoryTestRunner`) operates independently
2. **Unified test result model** – Both runners generate consistent, reportable results
3. **Lean orchestration** – `Core.ps1` acts purely as loader and public API gateway
4. **Minimal refactoring** – Duplicate code initially; extract utilities only when patterns emerge
5. **Future modularity** – Designed to support PowerShell module conversion (`.psm1` files) later

---

## Architecture Overview

### Core Principles

```
Core.ps1 (Orchestrator & Entry Points)
├── Load Config.ps1
├── Load Core.PreFlightValidation.ps1
├── Load Core.Authentication.ps1
├── Load Core.CompileYaml.ps1
├── Load Core.SaveYaml.ps1
├── Load Core.ParameterisedTestRunner.ps1  ← NEW NAME for Core.TestRunner.ps1
├── Load Core.DirectoryTestRunner.ps1      ← NEW
└── Expose PUBLIC functions:
    ├── Run-Tests (delegates to Core.ParameterisedTestRunner)
    └── Run-DirectoryCompileTests (delegates to Core.DirectoryTestRunner)
```

### Framework Boundaries

**PUBLIC (via Core.ps1):**
- `Run-Tests`
- `Run-DirectoryCompileTests`

**PRIVATE (script: prefix, internal only):**
- All helper/utility functions
- All test state management
- All reporting formatting
- All validation logic

**REUSABLE (available to both runners):**
- `Test-CompileYaml` (from Core.CompileYaml.ps1)
- `Save-CompiledYaml` (from Core.SaveYaml.ps1)
- Authentication token (from Core.Authentication.ps1)

---

## Unified Test Result Model

Both `ParameterisedTestRunner` and `DirectoryTestRunner` use the same result structure:

```powershell
$testResult = @{
  Name          = "build_test"                    # Identifier of what was tested
  Group         = "terraform_build"               # Category/directory
  Success       = $true                           # Pass/fail
  Error         = $null                           # Error message if failed
  Duration      = 125                             # Duration in ms
  Type          = "DirectoryCompile"              # "ParameterisedTest" or "DirectoryCompile"
}
```

### Test Types

| Type                    | Example Name              | Example Group             | Context                                    |
|-------------------------|---------------------------|---------------------------|--------------------------------------------|
| **ParameterisedTest**   | `with custom parameters`  | `terraform_build`         | Specific test case from `-ValidTestCases` |
| **DirectoryCompile**    | `build_test`              | `terraform_build`         | File discovered in directory scan         |

### Reporting Benefits

- **Unified output formatting** across both test runners
- **Consistent filtering** (filter by group, name, or type)
- **Common aggregation logic** (summary statistics)
- **Future extensibility** (add new test types without UI changes)

---

## File Organization

### Current Framework Files (Unchanged)

```
tests/framework/
├── Config.ps1                           # Environment configuration
├── Core.PreFlightValidation.ps1         # Pre-execution checks
├── Core.Authentication.ps1              # Token management
├── Core.CompileYaml.ps1                 # Azure DevOps REST API
├── Core.SaveYaml.ps1                    # YAML persistence
```

### Updated Files

```
tests/framework/
├── Core.ps1                             # REFACTORED: Orchestrator only
├── Core.TestRunner.ps1                  # RENAMED to Core.ParameterisedTestRunner.ps1
```

### NEW Files

```
tests/framework/
├── Core.DirectoryTestRunner.ps1         # NEW: Directory-based testing
```

---

## Core.ps1 Refactoring

### Current State Problem

`Core.ps1` currently contains:
- Initialization code ✓
- Orchestration logic ✓
- Public function definitions ✓
- Test execution logic ✗ (should be in test runner)
- Test state management ✗ (hybrid between Core.ps1 and Core.TestRunner.ps1)
- Reporting logic ✗ (mixed concerns)

### Target State

`Core.ps1` should contain ONLY:

```powershell
# 1. Configuration Loading
. (Join-Path $PSScriptRoot "Config.ps1")

# 2. Module Auto-Loader
Get-ChildItem -Path $PSScriptRoot -Filter "Core.*.ps1" | ForEach-Object { . $_.FullName }

# 3. Preflight Validation
Invoke-PreFlightValidation

# 4. Authentication
Initialize-AzureDevOpsAuthentication

# 5. PUBLIC ENTRY POINTS ONLY
function Run-Tests
{
  # Minimal wrapper that delegates to Core.ParameterisedTestRunner
  param(...)
  Invoke-ParameterisedTests @PSBoundParameters
}

function Run-DirectoryCompileTests
{
  # Minimal wrapper that delegates to Core.DirectoryTestRunner
  param(...)
  Invoke-DirectoryCompileTests @PSBoundParameters
}
```

### Key Changes

- ❌ Remove test execution logic from Core.ps1
- ❌ Remove test state from Core.ps1 (each runner manages its own)
- ❌ Remove reporting logic from Core.ps1
- ✅ Keep initialization code
- ✅ Keep public function wrappers
- ✅ Import all helper functions via module loading

---

## Test Runner Architecture

### Core.ParameterisedTestRunner.ps1

**Responsibilities:**
- Manage parameterised test state
- Execute test cases (existing `Run-Test` logic)
- Generate parameterised test results
- Format parameterised test output

**Functions (all private by default):**

```powershell
# Entry point (called by public Run-Tests)
function Invoke-ParameterisedTests
{
  param(
    [string] $YamlPath,
    [array] $ValidTestCases,
    [array] $InvalidTestCases
  )
  # Main orchestration for parameterised tests
}

# Helper: Initialize test state
function script:Initialize-ParameterisedTestState { }

# Helper: Execute single test case
function script:Run-ParameterisedTest { }

# Helper: Validate test case structure
function script:Test-ParameterisedTestCase { }

# Helper: Evaluate compilation results
function script:Evaluate-CompilationResult { }

# Helper: Format output for parameterised results
function script:Format-ParameterisedTestOutput { }

# Helper: Throw exception if tests failed
function script:Throw-OnParameterisedTestFailure { }

# State variable
$script:ParameterisedTestState = @{
  TestsRun = 0
  Passed = 0
  Failed = 0
  Results = @()
}
```

### Core.DirectoryTestRunner.ps1

**Responsibilities:**
- Manage directory test state
- Discover `*_test.yml` files (recursive in specified directory)
- Execute directory tests
- Generate directory test results
- Format directory test output

**Functions (all private by default):**

```powershell
# Entry point (called by public Run-DirectoryCompileTests)
function Invoke-DirectoryCompileTests
{
  param(
    [string] $DirectoryPath
  )
  # Main orchestration for directory tests
}

# Helper: Initialize test state
function script:Initialize-DirectoryTestState { }

# Helper: Discover all *_test.yml files in directory (recursive)
function script:Find-TestYamlFilesInDirectory { }

# Helper: Execute single discovered file
function script:Run-DirectoryTest { }

# Helper: Validate directory path
function script:Test-DirectoryTestInput { }

# Helper: Evaluate compilation results
function script:Evaluate-DirectoryCompilationResult { }

# Helper: Format output for directory results
function script:Format-DirectoryTestOutput { }

# Helper: Throw exception if tests failed
function script:Throw-OnDirectoryTestFailure { }

# Helper: Extract display name from file path
function script:Get-TestFileDisplayName { }

# State variable
$script:DirectoryTestState = @{
  FilesFound = 0
  FilesRun = 0
  Passed = 0
  Failed = 0
  Results = @()
}
```

### Shared Functions (No Refactor Now)

These functions can be called by both runners. **Duplication is acceptable initially:**

```powershell
# Both runners may have these (duplicated):
function script:Test-CompileValidation { }          # Returns $true if id == -1 && finalYaml != null
function script:Evaluate-CompilationResult { }      # Shared logic to check success

# Available from other modules:
Test-CompileYaml (from Core.CompileYaml.ps1)
Save-CompiledYaml (from Core.SaveYaml.ps1)
$script:AuthToken (from Core.Authentication.ps1)
```

**Future consideration:** Extract to `Core.TestingUtilities.ps1` once pattern stabilizes.

---

## Directory Discovery Behavior

### Scope

**Input:** `tests/jobs/terraform_build`

**Discovery (finds all *_test.yml, including in subdirectories):**
```
✓ tests/jobs/terraform_build/build_test.yml
✓ tests/jobs/terraform_build/subdir/additional_test.yml        ← Nested
✓ tests/jobs/terraform_build/other_subdir/special_test.yml     ← Nested
```

### Search Algorithm

```powershell
Get-ChildItem -Path $DirectoryPath -Filter "*_test.yml" -Recurse
```

**Parameters:**
- `-Recurse` searches all subdirectories
- Always used (no "non-recursive" mode for now)

---

## Function Signatures

### Public API

```powershell
# EXISTING - No changes
function Run-Tests
{
  param(
    [Parameter(Mandatory)]
    [string]
    $YamlPath,

    [Parameter(Mandatory)]
    [array]
    $ValidTestCases,

    [Parameter(Mandatory)]
    [array]
    $InvalidTestCases
  )
}

# NEW
function Run-DirectoryCompileTests
{
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DirectoryPath
  )
}
```

**Key Points:**
- ✅ `Run-Tests` signature completely unchanged (backward compatible)
- ✅ `Run-DirectoryCompileTests` accepts directory path only
- ❌ NO `MaxParallelTests` parameter (deferred to Phase 2)
- ❌ NO `RecursiveSearch` parameter (always recursive)

---

## Test Result Output Format

### Unified Result Object

Both runners produce results conforming to this structure:

```powershell
@{
  Name      = "test_identifier"        # E.g., "build_test" or "with custom parameters"
  Group     = "group_name"             # E.g., "terraform_build" or "terraform_deploy"
  Success   = $true|$false             # Pass/fail indicator
  Error     = $null|"error message"    # Error details if failed
  Duration  = 125                      # Milliseconds
  Type      = "DirectoryCompile"|"ParameterisedTest"  # Test type
}
```

### Output Example: Directory Mode

```
Testing Directory: tests/jobs/terraform_build

  Testing: build_test
    ✓ Default compilation (127 ms)

  Testing: additional_files_test
    ✓ Default compilation (112 ms)

  Testing: injection_steps_test
    ✓ Default compilation (145 ms)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Directory Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Files Discovered: 3
  Files Tested:     3
  Passed:           3
  Failed:           0
  Total Duration:   384 ms
```

### Output Example: Parameterised Mode (Existing)

```
Testing: terraform_build/build_test

  Test Case 1: with default parameters
    ✓ PASSED (98 ms)

  Test Case 2: with custom artifact directory
    ✓ PASSED (102 ms)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Test Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Tests Run:    2
  Passed:       2
  Failed:       0
  Total Time:   200 ms
```

---

## Helper Function Naming Convention

All private/helper functions use `script:` prefix to indicate scope:

```powershell
# PRIVATE - Internal helpers
function script:Initialize-ParameterisedTestState { }
function script:Run-ParameterisedTest { }
function script:Test-ParameterisedTestCase { }
function script:Evaluate-CompilationResult { }
function script:Format-ParameterisedTestOutput { }
function script:Throw-OnParameterisedTestFailure { }

# PRIVATE - Shared evaluation
function script:Test-CompileValidation { }

# PUBLIC - Entry points only
function Run-Tests { }
function Run-DirectoryCompileTests { }
```

**Rationale:**
- Clear visual distinction: public functions have no prefix
- Avoids accidental usage by external callers
- Ready for future module conversion (can map to `hidden` attribute)

---

## Implementation Phases

### Phase 1: Core Implementation (Immediate)

**Step 1.1:** Rename `Core.TestRunner.ps1` → `Core.ParameterisedTestRunner.ps1`
- Extract test execution logic from Core.ps1 if not already done
- Define `Invoke-ParameterisedTests` as entry point
- Ensure all helpers use `script:` prefix

**Step 1.2:** Create `Core.DirectoryTestRunner.ps1`
- Implement `Invoke-DirectoryCompileTests` entry point
- Implement `Find-TestYamlFilesInDirectory` for discovery
- Implement `Run-DirectoryTest` for single file execution
- Implement result aggregation and reporting
- All helpers use `script:` prefix

**Step 1.3:** Refactor `Core.ps1`
- Remove test execution logic
- Keep only initialization and public entry points
- Load all `Core.*.ps1` files via auto-loader (already exists)
- Ensure both `Run-Tests` and `Run-DirectoryCompileTests` delegate properly

**Step 1.4:** Test the implementation
- Verify `Run-Tests` still works (backward compatibility)
- Test `Run-DirectoryCompileTests` with:
  - `tests/jobs/terraform_build`
  - `tests/pipelines/terraform_pipeline`
  - Verify recursive discovery works
  - Verify results aggregate correctly

### Phase 2: Unified Result Model (Optional, Post-V1)

- Create shared result formatting utilities
- Unified filtering/aggregation across test types
- Common reporting functions
- Extract to `Core.TestingUtilities.ps1`

### Phase 3: PowerShell Module Conversion (Future)

- Convert `Core.*.ps1` files to `.psm1` modules
- Use `Export-ModuleMember` for public functions
- Keep `script:` prefix functions as hidden/internal
- Import via `Import-Module` instead of dot-sourcing

---

## State Management

### Parameterised Test State

```powershell
$script:ParameterisedTestState = @{
  TestsRun       = 0
  Passed         = 0
  Failed         = 0
  Results        = @()        # Array of test result objects
  CurrentYamlPath = ""
  ErrorMessages  = @()
}
```

### Directory Test State

```powershell
$script:DirectoryTestState = @{
  FilesFound     = 0
  FilesRun       = 0
  Passed         = 0
  Failed         = 0
  Results        = @()        # Array of test result objects
  DirectoryPath  = ""
  ErrorMessages  = @()
}
```

### Why Separate?

- ✅ No crosstalk between test runners
- ✅ Clear ownership of state
- ✅ Easier to debug state issues
- ✅ Future parallel execution won't corrupt shared state
- ✅ Each runner can be tested independently

---

## Error Handling & Exit Codes

Both runners follow the same pattern:

```powershell
try
{
  # Discovery/Execution
  # Aggregation
  # Report results
}
catch
{
  # Log error
  # Add to error collection
}
finally
{
  # Format output
  # Throw exception if tests failed
  if ($script:*TestState.Failed -gt 0)
  {
    throw "Tests failed. See summary above."
  }
}
```

---

## Backward Compatibility

✅ **Guaranteed:**
- `Run-Tests` function signature unchanged
- `Run-Tests` behavior unchanged
- All existing `.CompileTests.ps1` files work as-is
- No modifications to `Core.CompileYaml.ps1`, `Core.Authentication.ps1`, etc.
- New functionality is purely additive

**Testing:**
- Run existing tests before and after changes
- Verify identical results

---

## Integration with CI/CD

### Example: New Pipeline for Directory Testing

```powershell
# tests/jobs/RunAllJobTests.ps1
if (-not (Get-Command -Name 'Run-DirectoryCompileTests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

Run-DirectoryCompileTests -DirectoryPath "tests/jobs"
```

### Example: Mixed Mode (Both Runners)

```powershell
# tests/RunAllTests.ps1
$repoRoot = git rev-parse --show-toplevel 2> $null
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Comprehensive test for critical template
. (Join-Path $repoRoot "tests" "tasks" "terraform.CompileTests.ps1")

# Directory bulk tests
Write-Host "Running directory tests..."
Run-DirectoryCompileTests -DirectoryPath "tests/jobs"
Run-DirectoryCompileTests -DirectoryPath "tests/pipelines"
```

---

## Success Criteria

The implementation is successful when:

1. ✅ `Run-DirectoryCompileTests` function exists and is callable
2. ✅ Auto-discovers ALL `*_test.yml` files in specified directory (including subdirectories)
3. ✅ Compiles each file using existing Azure DevOps API integration
4. ✅ Generates unified report with consistent result objects
5. ✅ `Run-Tests` remains unchanged and backward compatible
6. ✅ Test state properly separated (no crosstalk between runners)
7. ✅ All helper functions use `script:` prefix convention
8. ✅ Unified test result model works for both runners
9. ✅ Documentation shows usage examples and differences vs. `Run-Tests`
10. ✅ All existing tests pass without modification

---

## Migration Path (Optional)

### For Teams Adopting New Functionality

**Gradual Option:**
```powershell
# 1. Keep existing .CompileTests.ps1 files as-is
# 2. Add new directory runner scripts alongside them
# 3. Eventually consolidate if desired (not required)

# Step 1: Directory mode for jobs
Run-DirectoryCompileTests -DirectoryPath "tests/jobs"

# Step 2: Keep critical comprehensive tests
. (Join-Path $repoRoot "tests" "tasks" "terraform.CompileTests.ps1")

# Step 3: Later, remove individual .CompileTests.ps1 files if desired
```

---

## Future Enhancements (Not in Scope)

- ❌ Parallel execution (`-MaxParallelTests` parameter)
- ❌ Stop-on-first-failure
- ❌ Batch Azure DevOps API calls
- ❌ Config file defaults for directory testing

These can be added in Phase 2+ once core functionality is stable.

---

## Assumptions & Constraints

### Assumptions

1. Azure DevOps authentication token is obtained during `Core.ps1` initialization
2. All `*_test.yml` files are meant for standalone compilation (no interdependencies)
3. Test results follow the unified model for both runner types
4. Both runners should throw on failure (consistent with `Run-Tests`)

### Constraints

1. No parallel execution (sequential testing)
2. No recursive discovery toggle (always recursive)
3. Cannot modify existing `Run-Tests` signature
4. Must maintain 100% backward compatibility

---

## Implementation Checklist

- [ ] Rename `Core.TestRunner.ps1` → `Core.ParameterisedTestRunner.ps1`
- [ ] Extract test execution logic into `Invoke-ParameterisedTests` function
- [ ] Add `script:` prefix to all helper functions in parameterised runner
- [ ] Create `Core.DirectoryTestRunner.ps1` with core functions
- [ ] Implement `Invoke-DirectoryCompileTests` entry point
- [ ] Implement `Find-TestYamlFilesInDirectory` with recursive search
- [ ] Implement `Run-DirectoryTest` for single file execution
- [ ] Design and implement unified test result object
- [ ] Implement result aggregation and reporting
- [ ] Refactor `Core.ps1` to orchestrator-only pattern
- [ ] Add `Run-DirectoryCompileTests` public function to `Core.ps1`
- [ ] Test backward compatibility of `Run-Tests`
- [ ] Test new `Run-DirectoryCompileTests` with real directories
- [ ] Verify recursive discovery works correctly
- [ ] Create usage documentation with examples
- [ ] Verify all helper functions use `script:` prefix

---

## Conclusion

This implementation plan provides:

- **Clear separation of concerns** – Each test runner manages its own state and logic
- **Unified interface** – Both runners follow consistent patterns
- **Lean orchestration** – Core.ps1 remains simple and focused
- **Future-proof design** – Ready for module conversion and parallelization
- **Backward compatible** – No breaking changes to existing code

The design is ready for implementation in Phase 1.

