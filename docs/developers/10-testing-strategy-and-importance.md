# Testing Strategy and Importance

## Overview

The `devops-azdo-yaml-pipeline-templates` repository uses a comprehensive, multi-layered testing strategy to catch issues before they reach production environments. This document explains **why** this testing approach is essential and provides concrete examples from real-world scenarios.

---

## The Critical Problem: Silent Failures in Pipeline Templates

### Why Testing Matters

Azure DevOps YAML pipeline templates are **executable infrastructure code**. Unlike traditional software with syntax checking at compile time, YAML template errors often manifest only when:

1. A pipeline runs (not when code is pushed)
2. A pipeline runs with specific parameter combinations (not all scenarios)
3. A downstream template is affected by a change in an upstream template (cascading failures)

**Without testing, a breaking change can propagate silently through the repository and fail in production environments where pipelines are actively running.**

### Real-World Example: The `concat_wrap_list.yml` Cascade Failure

This scenario demonstrates why testing is critical:

#### What Happened

A developer enhanced `utils/concat_wrap_list.yml` with stricter validation:

```yaml
# CHANGE: Added validation to reject empty Items lists
- ${{ if and(contains(convertToJson(parameters.Items), '['), eq(length(parameters.Items), 0)) }}:
    - "Invalid Parameter: Items cannot be empty. If no concat wrapped list is needed, omit this template entirely.": "Error"
```

The change makes sense in isolation—catching programming errors early. However, **the validation broke 23+ tests** in downstream templates because:

1. `jobs/terraform_deploy.yml` uses `concat_wrap_list.yml` to build command options:
   ```yaml
   - template: /utils/concat_wrap_list.yml
     parameters:
       Items: ${{ parameters.TerraformDeploymentConfig.VariableFiles }}  # Can be empty!
       OutputVariableName: VariableFilesCommandOption
   ```

2. When consumers don't provide `VariableFiles` (a valid scenario), `concat_wrap_list.yml` receives an empty list.

3. The new validation rejects this, causing **cascading failures through**:
   - `jobs/terraform_deploy.yml` (23 test failures)
   - `jobs/terraform_gated_deployment.yml` (15 test failures)
   - `tests/jobs/jobs.CompileTests.ps1` (1 test failure)

#### Test Results Revealed the Problem

```
Running: jobs/terraform_deploy.CompileTests.ps1
...
TEST SUMMARY
  Tests Run:    33
  Passed:       10
  Failed:       23

Failed Tests:
  - Plan Mode - Basic
  - Apply Mode - Basic
  - Plan with VerifyOnDestroy
  ... (20 more failures)
```

**Outcome**: Tests caught the breaking change **before** it was committed to the server, preventing production pipeline failures.

---

## Testing Layers in This Repository

### Layer 1: Unit Tests (Template-Specific)

**Location**: `[template-name].CompileTests.ps1` in the same directory as the template.

**Purpose**: Verify that a single template works correctly in isolation.

**Example**: `utils/concat_wrap_list.CompileTests.ps1`

```powershell
$validTestCases = @(
  @{
    Description = "with simple wrapped list"
    Parameters = @{
      Items = @('A', 'B')
      Prefix = '('
      Suffix = ')'
      OutputVariableName = 'MyResult'
    }
    ExpectedYaml = @(
      'name: MyResult'
      'value: (A)(B)'
    )
  }
)
```

**Why it matters**:
- Validates that the template produces correct output for valid inputs
- Verifies that validation rules work as intended
- Documents expected behavior through test cases

**Limitation**: Unit tests don't reveal when a template's contract changes in incompatible ways.

### Layer 2: Integration Tests (Multi-Template)

**Location**: `tests/jobs/jobs.CompileTests.ps1`, `tests/pipelines/pipelines.CompileTests.ps1`

**Purpose**: Verify that multiple templates work together correctly.

**Example**: `terraform_deploy.CompileTests.ps1` tests `terraform_deploy.yml` with all its internal template dependencies:

```powershell
@{
  Description = "Plan Mode - Basic"
  Parameters = @{
    EnvironmentName = "dev"
    TerraformDeploymentConfig = @{
      AzDOEnvironmentName = "compile-tests-only"
      RunMode = "PlanOnly"
    }
  }
  ExpectedYAML = @(...)
}
```

**Why it matters**:
- **Catches breaking changes in dependent templates** (like the `concat_wrap_list.yml` case)
- Tests realistic parameter combinations that consumers actually use
- Validates that template composition works end-to-end

**Why the cascade was caught**: Integration tests exercise real downstream templates with their actual parameter patterns.

### Layer 3: Compile Tests (Repository-Wide)

**Location**: `Run-AllCompileTests.ps1`

**Purpose**: Run all 12+ compile test files to verify the entire repository is consistent.

**Why it matters**:
- Ensures that **no one change breaks multiple templates**
- Catches circular dependencies or inconsistent contracts
- Provides a quick CI/CD gate before merging

---

## Why This Matters: Consequences Without Testing

### Scenario A: Without Integration Tests

If only unit tests existed:

1. ✅ `concat_wrap_list.CompileTests.ps1` passes (new validation works on non-empty lists)
2. ❌ Change is pushed to server
3. ❌ First consumer to use `VariableFiles: []` encounters runtime failure
4. ❌ Debugging involves reproducing in staging/production
5. ❌ Root cause is buried in template composition, not obviously the `concat_wrap_list.yml` change

**Cost**: Days of debugging, production impact, emergency rollback.

### Scenario B: With Integration Tests (Actual Outcome)

1. ✅ `concat_wrap_list.CompileTests.ps1` passes
2. ❌ `terraform_deploy.CompileTests.ps1` fails immediately (23 failures)
3. ✅ Developer sees the connection: "My change broke all these tests"
4. ✅ Root cause is obvious: "Items cannot be empty" from `concat_wrap_list.yml`
5. ✅ Decision: Fix `terraform_deploy.yml` to only call `concat_wrap_list.yml` when items exist, OR revert the validation, OR fix the validation logic
6. ✅ Change is corrected before reaching production

**Cost**: 10 minutes debugging; change never reaches production.

---

## Key Testing Principles

### 1. Test the Contract, Not Just the Implementation

**Good contract testing**:
```powershell
@{
  Description = "with empty VariableFiles (valid scenario)"
  Parameters = @{
    EnvironmentName = "dev"
    TerraformDeploymentConfig = @{
      AzDOEnvironmentName = "compile-tests-only"
      RunMode = "PlanOnly"
      VariableFiles = @()  # Empty list is a valid scenario
    }
  }
}
```

Tests verify that **valid parameter combinations work**, even edge cases like empty lists.

### 2. Test Integration Points

Every template that calls another template **must** have integration tests:

```
terraform_deploy.yml
  ├─ Calls: /utils/concat_wrap_list.yml (VariableFiles)
  ├─ Calls: /utils/concat_wrap_list.yml (BackendConfig)
  └─ Must have tests for all these call sites
```

**Why**: A change to `concat_wrap_list.yml` must be validated against **all** its call sites.

### 3. Test Edge Cases

The cascade failure was caught because tests included:

- ✅ Minimal parameters (exercises default behavior)
- ✅ Empty lists (exercises boundary conditions)
- ✅ Complex nested objects (exercises realistic scenarios)

**Without edge case tests**: The empty list scenario would have passed silently until production.

### 4. Test Error Conditions

Invalid test cases verify that templates **reject bad input**:

```powershell
$invalidTestCases = @(
  @{
    Description = "with invalid OutputVariableName type"
    Parameters = @{
      Items = @('A', 'B')
      OutputVariableName = @{ Name = 'NotAString' }  # Wrong type
    }
    ErrorMessage = "Invalid Parameter: Field 'OutputVariableName' must be a string."
  }
)
```

**Why**: Validates that templates fail gracefully with clear error messages, not silent corruption.

---

## Testing in Your Development Workflow

### Before Committing Code

Run all tests locally:

```powershell
# Test only the template you changed
./jobs/terraform_deploy.CompileTests.ps1

# Run ALL tests to catch cascade failures
./Run-AllCompileTests.ps1
```

**Time investment**: 2-5 minutes
**ROI**: Prevents production failures

### When Adding/Removing Parameters

Update tests **at the same time** as the template:

```powershell
# If you add a parameter:
1. Add parameter to template
2. Add test case for that parameter
3. Add test case for missing parameter (if required)
4. Run tests before committing
```

**Why**: Tests must pass before code can be merged. This enforces that changes and their effects are understood together.

### When Modifying Existing Templates

**ALWAYS** run the integration tests of **templates that use** your template:

```
Modified: utils/concat_wrap_list.yml
Therefore must run: jobs/terraform_deploy.CompileTests.ps1 (calls concat_wrap_list)
```

---

## Real-World Impact: The Cascade Failure Statistics

**Without testing, this single change would have affected**:

| Template | Impact | Detected By |
|----------|--------|-------------|
| `jobs/terraform_deploy.yml` | 23 test failures | Integration tests |
| `jobs/terraform_gated_deployment.yml` | 15 test failures | Integration tests |
| `tests/jobs/jobs.CompileTests.ps1` | 1 test failure | Integration tests |
| **Total** | **39 failures across 3 files** | **All detected before production** |

**Estimated debugging time without tests**: 4-8 hours
**Estimated debugging time with tests**: 10 minutes
**ROI of writing these tests**: 24:1 to 48:1

---

## When Tests Fail: What It Means

### Test Failure = Breaking Change Detected

A test failure **always means one of**:

1. **Your change broke downstream usage** (most common)
   - Solution: Fix your change to be backward compatible
   - OR update downstream templates to accommodate the change
   - OR revise your change to avoid breaking compatibility

2. **You changed expected behavior** (intentional breaking change)
   - Solution: Update the corresponding test to reflect new behavior
   - AND update `CHANGELOG.md` with **BREAKING** prefix
   - AND increment major version

3. **The test itself is wrong** (rare)
   - Solution: Fix the test if it's testing for unrealistic scenarios
   - Update documentation to reflect actual requirements

**Never ignore a test failure.** It's the testing system's way of saying "this change has consequences."

---

## Common Testing Scenarios

### Scenario 1: Adding a New Optional Parameter

```powershell
# Your change
Parameters:
  - name: NewParameter
    type: string
    default: 'sensible-default'

# Your test
@{
  Description = "with NewParameter provided"
  Parameters = @{ NewParameter = 'custom-value' }
}

@{
  Description = "with default NewParameter (omitted)"
  Parameters = @{ }  # Test that default works
}
```

**Expected result**: ✅ All tests pass (backward compatible)

### Scenario 2: Changing Parameter Type

```powershell
# Your change
OLD: Items (object)  # object type
NEW: Items (string)  # string type (BREAKING!)

# Test failure
[FAIL] with array of items  # Can't pass @() anymore
Error: Parameter type mismatch

# What to do
Option 1: Revert the change (maintain compatibility)
Option 2: Update all call sites to pass strings (major version bump)
Option 3: Accept both types with parameter validation
```

**Expected result**: ❌ Test fails; forces decision about breaking change

### Scenario 3: Adding Validation

```powershell
# Your change
- ${{ if condition }}:
    - "ErrorMessage": "Error"

# Test should verify
@{
  Description = "with invalid input that should error"
  Parameters = @{ InvalidInput = 'bad-value' }
  ErrorMessage = "ErrorMessage"
}
```

**Expected result**: ✅ Test catches error; validates validation works

---

## Documentation Relationship

Tests and documentation are interconnected:

| When You | Also Do |
|----------|---------|
| Add parameter | Add test case + update in-file docs |
| Remove parameter | Remove test case + update in-file docs + CHANGELOG |
| Change behavior | Update test expectations + update docs + CHANGELOG |
| Add validation | Add invalid test case + document the validation |

**Why**: Tests serve as executable documentation. They show exactly how templates are supposed to be used.

---

## Troubleshooting Test Failures

### Failure: "Items cannot be empty. If no concat wrapped list is needed, omit this template entirely."

**Meaning**: A template is calling `concat_wrap_list.yml` with an empty list, but the new validation rejects this.

**Solution**:
```yaml
# Before
- template: /utils/concat_wrap_list.yml
  parameters:
    Items: ${{ parameters.Config.SomeList }}

# After - Only call if items exist
- ${{ if ne(length(parameters.Config.SomeList), 0) }}:
    - template: /utils/concat_wrap_list.yml
      parameters:
        Items: ${{ parameters.Config.SomeList }}
```

### Failure: "Expected finalYaml populated; API Error"

**Meaning**: Template compilation failed during Azure DevOps YAML validation.

**Debug steps**:
1. Check error message (usually includes file name and line number)
2. Look for validation errors in the mentioned template
3. Trace backward to see which template call caused the error
4. Review recent changes to that template

---

## Summary: Why Testing Is Non-Negotiable

| Aspect | Without Testing | With Testing |
|--------|-----------------|--------------|
| **Breaking changes detected** | In production (disaster) | Before merge (prevented) |
| **Root cause diagnosis** | 4-8 hours debugging | 10 minutes debugging |
| **Impact scope understanding** | Discovered late | Known immediately |
| **Confidence in merging** | Low (fingers crossed) | High (data-driven) |
| **Regression prevention** | Not possible | Guaranteed by suite |
| **Documentation verification** | Manual checking | Automated validation |
| **Cost of a mistake** | Very high | Very low |

**Testing is insurance against cascading failures.** In infrastructure-as-code repositories, that insurance is invaluable.

---

## Next Steps

1. **Understand the test framework**: Read `tests/framework/Core.ps1`
2. **Review real examples**: Look at `jobs/terraform_deploy.CompileTests.ps1`
3. **Run tests locally** before pushing: `./Run-AllCompileTests.ps1`
4. **When writing templates**: Write tests simultaneously
5. **When updating templates**: Update tests before committing

**Remember**: A template without tests is like production code without a CI/CD pipeline. It works until it doesn't—and that matters in infrastructure automation.

