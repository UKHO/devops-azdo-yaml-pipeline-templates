# Testing Framework Analysis & Recommendations

**Date:** April 24, 2026  
**Purpose:** Analysis of current testing framework architecture and recommendations for adding directory-based compilation testing functionality.

---

## Executive Summary

The current testing framework (`tests/framework/Core.ps1`) is well-designed for **comprehensive test case validation** with multiple test scenarios per file. However, for the `tests/jobs` and `tests/pipelines` directories, a significant portion of test files only validate basic compilation without asserting specific YAML content. This represents an opportunity to:

1. **Add new functionality** for simpler directory-based compilation testing
2. **Reduce boilerplate** in test files that only check compilation
3. **Maintain backward compatibility** with the existing `Run-Tests` function
4. **Improve maintainability** through optional refactoring

---

## Current Architecture Analysis

### File Structure

```
tests/framework/
├── Core.ps1                      # Main entry point & orchestrator
├── Core.CompileYaml.ps1          # Azure DevOps REST API integration
├── Core.TestRunner.ps1           # Test execution & reporting
├── Core.PreFlightValidation.ps1  # Environment validation
├── Core.Authentication.ps1       # Token management
├── Core.SaveYaml.ps1             # Compiled YAML persistence
└── Config.ps1                    # Environment configuration
```

### Framework Initialization Flow

1. `Core.ps1` loads configuration and all `Core.*.ps1` modules
2. Runs preflight validation checks
3. Obtains Azure DevOps access token
4. Exposes two main functions: `Run-Tests` and `Get-TestSummary` # I'm thinking to myself that the `Get-TestSummary` function should not be exposed, the `Run-Tests` should be exposed, that is what the outer files are calling, but the other function is not to be called by anyone else

### Current Test Execution Flow

```
CompileTests.ps1
  ├─ Load Framework (Core.ps1)
  ├─ Define TestCases array
  │   └─ @{ Description, Parameters, ExpectedYaml/ErrorMessage }
  └─ Call Run-Tests
       └─ Run-Test (invokes per test case)
            └─ Invoke-Test (Azure DevOps compilation)
                 └─ Test-CompileYaml (REST API call)
```

---

## Pattern Analysis

### Test File Patterns in `tests/jobs` and `tests/pipelines`

Analysis of 20+ `.CompileTests.ps1` files reveals:

| Pattern                 | Count | Percentage | Description                                                           |
|-------------------------|-------|------------|-----------------------------------------------------------------------|
| **Minimal Tests**       | ~15   | 75%        | Single valid test case with empty `ExpectedYaml` and no invalid cases |
| **Comprehensive Tests** | ~5    | 25%        | Multiple test cases with specific YAML assertions                     | # I am concerned if there are any CompileTests files that do have more than the bare minimal tests...
| **Framework Overhead**  | 100%  | 100%       | All files include 10+ lines of boilerplate for framework loading      |

### Example: Minimal Test Pattern # Yeah these are repeating a lot, and also the description is just redundant at this point... having a dedicated test for compiling files in the directory would be able to give better information

```powershell
# tests/jobs/terraform_build/build_test.CompileTests.ps1
$validTestCases = @(
  @{
    Description = "with default parameters"
    Parameters = @{ }
    ExpectedYaml = @()  # ← Empty! Just checking compilation
  }
)
$invalidTestCases = @()  # ← No invalid cases

Run-Tests `
  -YamlPath "tests/jobs/terraform_build/build_test.yml" `
  -ValidTestCases $validTestCases `
  -InvalidTestCases $invalidTestCases
```

### Key Observation # Yep these look good

These files **only validate that YAML compiles successfully**, not the compiled output content. The current framework works well for this, but the pattern suggests an opportunity for:
- Simpler API for "compilation-only" testing
- Automatic file discovery (no need to list each `_test.yml` file)
- Reduced boilerplate

---

## Identified Pain Points

### 1. **Boilerplate Repetition** # This probably consumes a lot of time as well to load everything...
Every `.CompileTests.ps1` file repeats the same structure:
- Framework loading check
- Empty test case definitions
- Single `Run-Tests` invocation

**Impact:** ~25-30% of test file content is boilerplate

### 2. **Manual File Discovery** # Yep this will introduce constant toil and there does not need to be this toil in place
Currently, tests must be individually executed or manually listed:
- No automatic discovery of `*_test.yml` files in a directory
- Each test requires its own `.CompileTests.ps1` file
- CI/CD pipelines must explicitly invoke each test file

**Impact:** Adding new tests requires creating the `.CompileTests.ps1` wrapper

### 3. **Semantic Mismatch** # Yeah it is messy way of having it all set up... The Run-Tests is definitely not valid for what I need when it comes to these files
Using `Run-Tests` with empty test cases doesn't clearly express intent:
```powershell
# What does this do? It's not obvious without reading the code
Run-Tests -YamlPath "..." -ValidTestCases @(@{ Description="..."; Parameters=@{}; ExpectedYaml=@() }) -InvalidTestCases @()
```

**Impact:** Reduced code clarity and increased cognitive load for new contributors

### 4. **Limited Batch Testing** # Yep it is more and more files that suddenly need to be written and then the CI/CD then needs to be updated to run all of these files...
No built-in support for testing multiple files in a directory:
- Each directory has 4-8 `*_test.yml` files
- Each requires its own `.CompileTests.ps1` invocation
- No single entry point for a directory's tests

**Impact:** CI/CD pipelines are verbose; testing a directory requires multiple steps

---

## Proposed New Functionality

### High-Level Design: `Run-DirectoryCompileTests`

A new function that:
1. **Accepts a directory path** (relative to repository root)
2. **Auto-discovers** all `*_test.yml` files in that directory # will it look in the subdirectories in the directory?
3. **Tests each file** with simple compilation validation
4. **Generates unified reporting** across all discovered files # yes clear reporting will be helpful
5. **Maintains backward compatibility** with existing `Run-Tests` function # this is a must, future refactoring can come into it to clean up the code

### Function Signature # It would be great to see if we can make it more Parallel in the running of the tests... Though to start with, let's consider the ParallelTests to be out of scope for now... I worry it will complicate things too much

```powershell
function Run-DirectoryCompileTests
{
  param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]
    $DirectoryPath,

    [Parameter()]
    [ValidateRange(0, [int]::MaxValue)]
    [int]
    $MaxParallelTests = 1,

    [Parameter()]
    [switch]
    $RecursiveSearch
  )
}
```

### Usage Example

```powershell
# Instead of multiple Run-Tests calls:
Run-DirectoryCompileTests -DirectoryPath "tests/jobs/terraform_build"

# With recursion (to find tests in nested subdirectories):
Run-DirectoryCompileTests -DirectoryPath "tests" -RecursiveSearch

# With parallel execution (advanced):
Run-DirectoryCompileTests -DirectoryPath "tests/pipelines/terraform_pipeline" -MaxParallelTests 3
```

### Behavior

**Input Path:** `tests/jobs/terraform_build`

**Discovery (non-recursive):**
```
✓ tests/jobs/terraform_build/build_test.yml
✓ tests/jobs/terraform_build/additional_files_test.yml
✓ tests/jobs/terraform_build/injection_steps_test.yml
✓ tests/jobs/terraform_build/double_build_test.yml
```

**Execution:** # OK yeah this looks good
```
For each *_test.yml:
  1. Load file content
  2. Call Test-CompileYaml with default parameters
  3. Validate id == -1 and finalYaml is not null
  4. Record pass/fail
  5. Aggregate results
```

**Output:** # Ok the output is something that could change easily... Probably doesn't matter too much at the moment though when there is nothing ATM
```
Testing: terraform_build/build_test
  ✓ Default compilation
  
Testing: terraform_build/additional_files_test
  ✓ Default compilation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 TEST SUMMARY (Directory Mode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Files Found:  4
  Tests Run:    4
  Passed:       4
  Failed:       0
```

---

## Implementation Recommendations

### Phase 1: Add New Functionality (Non-Breaking)

#### 1.1 Create New Module: `Core.DirectoryTestRunner.ps1`

**Location:** `tests/framework/Core.DirectoryTestRunner.ps1`

**Responsibilities:**
- File discovery logic
- Directory validation
- Batch test orchestration
- Aggregated reporting

**Key Functions:**
```powershell
function Find-TestYamlFiles # Yep sounds fine
  # Discover *_test.yml files in directory

function Run-DirectoryCompileTests # yep sounds fine
  # Main entry point for directory-based testing

function Run-DirectoryTest # Yep OK
  # Execute single test from directory batch

function Format-DirectoryTestSummary # yep OK
  # Generate aggregated summary output
```

#### 1.2 Update `Core.ps1`

Add the new module to auto-load: # Yeah the auto-load should handle the new file automatically
```powershell
# In Core.ps1 (after line 8)
Get-ChildItem -Path $frameworkRoot -Filter "Core.*.ps1" | ForEach-Object { . $_.FullName }
# ↑ Already loads all Core.*.ps1 files, no changes needed!
```

**No changes required** – the existing auto-loader already includes new `Core.*.ps1` files.

#### 1.3 Extend Test State # Hmm... I am wondering if I need a different approach, but we'll go with the following for now, it may be that a refactor clears it all up

Update `$script:TestState` in `Core.ps1` to support directory mode:
```powershell
$script:TestState = @{
  # ...existing entries...
  DirectoryMode = $false
  FilesTestedInDirectory = 0
  DirectoryTestResults = @()
}
```

### Phase 2: Optional Refactoring (Backward Compatible)

#### 2.1 Extract Common Pass Criteria # I think I want to extract all of the Criteria functions out to somewhere else, the Core.ps1 file is quite busy with it all and it could do with simplification... Ideally I would not see much in that core file at all... That all of the test runners are self contained in their own files and the core.ps1 file is just about pulling the right things in and setting up the right stuff

Move evaluation logic to separate functions:
```powershell
function Test-CompileValidation
  # Returns $true if compilation successful

function Test-CompileWithExpectations # yeah this seems good
  # Returns $true if compiled output matches ExpectedYaml
```

**Benefit:** DRY principle; reusable across `Run-Tests` and `Run-DirectoryCompileTests`

#### 2.2 Standardize Test Case Structure # Hmm OK, will need to see the implementation

Define parameter object validation:
```powershell
function Validate-TestCase
  # Ensures test case has required properties

function Validate-DirectoryTestInput
  # Validates directory path and accessibility
```

#### 2.3 Create Reporting Utilities # Yeah some better reporting utilities would be good, I would want some amount of consistency in the reporting, what if there are future test runners that do other things... don't want to write the reporting stuff again...

Extract formatting logic:
```powershell
function Format-TestFileReport
  # Formats output for a single test file

function Format-AggregatedReport
  # Combines results from multiple tests
```

### Phase 3: Performance Enhancements (Future) # Any improvements on performance would be great... I am not sure how MaxParallelTests would work but I'm interested in a deeper design on that

- **Parallel Execution:** Support `-MaxParallelTests` parameter
- **Caching:** Avoid re-authentication for multiple files
- **Batch Compilation:** Explore Azure DevOps API batch operations
- **Circuit Breaker:** Stop on first failure (optional parameter)

---

## Refactoring Considerations

### What Should Change?

| Component                        | Refactor? | Rationale                                             |
|----------------------------------|-----------|-------------------------------------------------------|
| **Core.ps1**                     | No        | Current structure works well; new module fits pattern | # Eh, I am wondering if this file is quite large and contains a lot of code that the Core.TestRunner.ps1 would expect... I'm expecting a new test runner, so I don't know if TestRunner needs to become ParamaterisedTestRunner and then just have a DirectoryTestRunner file. The existing test styles 
| **Core.TestRunner.ps1**          | Maybe     | Extract reusable validation functions (non-breaking)  | # Eh, see the comment avoe
| **Core.CompileYaml.ps1**         | No        | Low-level API; no changes needed                      | # Yeah this file should be left as it is, should be purely about the compiling
| **Core.PreFlightValidation.ps1** | No        | Used for all tests; works as-is                       | # Yep this should be fine
| **Config.ps1**                   | Minor     | Maybe add new config options for directory defaults   | # I don't know what should be exposed in the configutation

### What Should NOT Change?

1. **Core.ps1 initialization flow** – Currently idiomatic and clean # I would like there to be less in the file actually... it got a lot of code in it 
2. **Run-Tests function signature** – Backward compatibility essential # 100%
3. **Test-CompileYaml behavior** – Core API; must remain stable # 100%
4. **Existing test files** – Remain unchanged even after new feature ships # 100%

### Backward Compatibility Strategy

- Existing `Run-Tests` calls continue unchanged # Yes all of these can't change right now
- New `Run-DirectoryCompileTests` is **additive, not replacement** # Tes
- All existing test files continue working as-is # Yes
- Optional gradual migration path available (but not required) # More details?

---

## Proposed Implementation Outline

### File: `tests/framework/Core.DirectoryTestRunner.ps1`

```powershell
# ============================================================================
# TEST FRAMEWORK - DIRECTORY-BASED COMPILATION TESTING
# ============================================================================
# Provides simplified batch compilation testing for directories containing
# multiple *_test.yml files. Useful for tests/jobs, tests/pipelines, and
# similar directory structures where files only validate compilation.

function Find-TestYamlFiles # Yep sounds good
{
  # Inputs: DirectoryPath, RecursiveSearch
  # Returns: Array of full paths to *_test.yml files
  # Logic:
  #   1. Validate directory exists
  #   2. Get-ChildItem with *_test.yml filter
  #   3. Return relative paths (for TelemetryState tracking)
}

function Run-DirectoryCompileTests # Yep sounds good
{
  # Inputs: DirectoryPath, MaxParallelTests, RecursiveSearch
  # Returns: void (updates $script:TestState)
  # Logic:
  #   1. Find-TestYamlFiles
  #   2. For each *.yml file:
  #      - Run-DirectoryTest
  #      - Track pass/fail
  #   3. Format-DirectoryTestSummary
  #   4. Throw-ExceptionOnTestFailure
}

function Run-DirectoryTest # Yep sounds good
{
  # Inputs: YamlFilePath
  # Returns: void (updates $script:TestState)
  # Logic:
  #   1. Load YAML content
  #   2. Test-CompileYaml with default parameters
  #   3. Validate compilation: id == -1 && finalYaml != null # Would be good if the reused pass criteria was included
  #   4. Invoke-Test for reporting
}

function Format-DirectoryTestSummary # Ok sure
{
  # Inputs: none (reads $script:TestState)
  # Returns: void (writes to output)
  # Logic:
  #   1. Display files tested count
  #   2. Show aggregated summary
  #   3. List any failures with file locations
  #   4. Consistent formatting with Run-Tests output
}

function Get-TestFileDisplayName # Ok perhaps this will get changed as we run the tests
{
  # Helper: Extract friendly name from path
  # Example: "tests/jobs/terraform_build/build_test.yml" → "build_test"
}
```

---

## Migration Path (Optional)

### For Teams Adopting New Functionality 

**Step 1:** Create directory compile tests gradually # OK
```powershell
# Create a new script in tests/jobs directory:
# Tests-All-Jobs.ps1
. (Join-Path (git rev-parse --show-toplevel) "tests" "framework" "Core.ps1")
Run-DirectoryCompileTests -DirectoryPath "tests/jobs"
```

**Step 2:** Individual test files remain (no obligation to migrate) # OK
```powershell
# tests/jobs/terraform_build/build_test.CompileTests.ps1
# Continue working unchanged
```

**Step 3:** Gradually consolidate if desired # OK, if the new file works, we will want to remove the files we don't need any more
```powershell
# Optional future: Remove redundant files if project standardizes on directory mode
# But this is NOT required and NOT breaking
```

---

## Configuration Considerations

### Potential New Config Options (Optional Enhancement) # Ok the DirectoryMode containing the bits is good

```powershell
# In Config.ps1
TestExecution = @{
  ShowVerboseOutput = $false
  ThrowExceptionOnTestFailure = $true
  DirectoryMode = @{
    DefaultMaxParallel = 1
    StopOnFirstFailure = $false
    RecursiveByDefault = $false
  }
}
```

---

## Testing the New Functionality

### Unit Test Strategy # Ok this is all a bit nope for me, I don't want to be having all of these testCases, the only information that I should be passing in is the directory path that I want to run, none of these test cases, not whatsoever.

```powershell
# tests/framework/Core.DirectoryTestRunner.CompileTests.ps1

$testCases = @(
  @{
    Description = "Discover test files in directory"
    Path = "tests/jobs/terraform_build"
    ExpectedCount = 4
  },
  @{
    Description = "Return relative paths"
    Path = "tests/pipelines/terraform_pipeline"
    ExpectedPattern = "*.yml"
  },
  @{
    Description = "Handle empty directory gracefully"
    Path = "tests/empty_directory"
    ExpectedCount = 0
  },
  @{
    Description = "Recursive search includes subdirectories"
    Path = "tests"
    RecursiveSearch = $true
    ExpectedMinimum = 20
  }
)
```

---

## Potential Challenges & Solutions 

| Challenge                              | Solution                                                     |
|----------------------------------------|--------------------------------------------------------------|
| **Framework state corruption**         | Use separate test state section for directory mode           | # yes it is the test state I worry about, I want to have two separate states, one for the original tests and then one for the new directory tests. Then inside the Core.*TestRunner.ps1 files, they could define what their test states are and inside of the Core.ps1, it pulls everything together as needed.
| **Unforeseen filtering edge cases**    | Comprehensive glob pattern testing; explicit file validation | # Fair
| **Performance with large directories** | Future parallel execution; for now, sequential is safe       | # Yeah I would want to understand how the parallel execution would work... Sequential is safe ATM, but faster tests is better tests, though unstable tests are worse than no tests
| **Mixing two test modes**              | Clear documentation; separate entry functions                | # Clear entry functions would help, the Core.ps1 could define both of these only and everything else is refactored
| **Test discovery ambiguity**           | Strict pattern: only `*_test.yml` files; no variations       |

---

## Risks & Risk Mitigation

| Risk                                      | Likelihood | Impact | Mitigation                                |
|-------------------------------------------|------------|--------|-------------------------------------------|
| **Backward compatibility break**          | Very Low   | High   | Don't modify `Run-Tests`; new module only | # Speaking of modules... perhaps it is possible to change all of the non Core.ps1 files into modules and then those can get imported with the required functions being exported as needed? Is that an easy thing to do?
| **Azure DevOps API quota issues**         | Low        | Medium | Test with small directories first         | # No idea if there is a quota issue?
| **File system pattern matching failures** | Medium     | Low    | Extensive testing on Windows/Linux paths  |
| **Authentication state issues**           | Low        | High   | Reuse existing token mechanism            |

---

## Success Criteria

The new functionality is successful if:

1. ✅ **New `Run-DirectoryCompileTests` function exists** and is callable # Yep
2. ✅ **Auto-discovers** `*_test.yml` files in specified directory # Yep
3. ✅ **Compiles each file** using existing Azure DevOps API integration # Yep
4. ✅ **Generates unified report** showing all results # Yep
5. ✅ **Backward compatible** – no existing tests require changes # Yep
6. ✅ **Documented** – function has comprehensive comment block and examples # Yep
7. ✅ **Tested** – unit tests cover normal and edge cases # Yep
8. ✅ **Follows project conventions** – consistent with existing code style # Yep

---

## Recommendations Summary

### Immediate Actions (High Priority)

1. **Create `Core.DirectoryTestRunner.ps1`** with:
   - `Find-TestYamlFiles` function
   - `Run-DirectoryCompileTests` entry point
   - `Run-DirectoryTest` single-file handler
   - Integration with existing `$script:TestState`

2. **Test the new module** with:
   - `tests/jobs/terraform_build` directory
   - `tests/pipelines/terraform_pipeline` directory
   - Validate discovery, compilation, and reporting

3. **Create documentation** showing:
   - Usage examples
   - When to use vs. `Run-Tests`
   - Migration guidelines

### Optional Enhancements (Phase 2+)

1. Parallel execution support
2. Improved error recovery
3. Batch compilation API exploration
4. Config-driven defaults

### Not Recommended (Anti-Patterns)

- ❌ Modifying existing `Run-Tests` function # Ok I think I am going to ask you to change this
- ❌ Removing backward compatibility
- ❌ Forced migration of existing test files
- ❌ Automatic directory testing in CI/CD without explicit invocation

---

## Appendix: Code Structure Examples

### Example: New Test Script Using Directory Mode

```powershell
# tests/jobs/RunAllJobTests.ps1
if (-not (Get-Command -Name 'Run-DirectoryCompileTests' -ErrorAction SilentlyContinue))
{
  $repoRoot = git rev-parse --show-toplevel 2> $null
  . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

Run-DirectoryCompileTests -DirectoryPath "tests/jobs"
```

**Benefit:** Replace 10+ individual test invocations with a single, clear function call.

### Example: Mixed Mode (Both Comprehensive & Directory Tests)

```powershell
# tests/RunAllTests.ps1
$repoRoot = git rev-parse --show-toplevel 2> $null
. (Join-Path $repoRoot "tests" "framework" "Core.ps1")

# Comprehensive tests for critical templates
. (Join-Path $repoRoot "tests" "tasks" "terraform.CompileTests.ps1")

# Directory-based compilation tests for jobs and pipelines
Run-DirectoryCompileTests -DirectoryPath "tests/jobs"
Run-DirectoryCompileTests -DirectoryPath "tests/pipelines"
```

**Benefit:** Flexible mix-and-match approach accommodates different testing needs.

---

## Conclusion

The proposed `Run-DirectoryCompileTests` functionality:
- **Addresses real pain points** identified in 75% of test files
- **Maintains backward compatibility** with zero breaking changes
- **Reduces boilerplate** by 80-90% for compilation-only tests
- **Improves clarity** by using semantically meaningful function names
- **Enables batch testing** of multiple files with single invocation
- **Follows existing patterns** established in the framework

Implementation is **low-risk**, **high-value**, and can coexist peacefully with the existing `Run-Tests` function.


