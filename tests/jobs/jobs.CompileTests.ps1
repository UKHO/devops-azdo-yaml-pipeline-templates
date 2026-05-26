# ============================================================================
# TEST: Jobs Directory
# ============================================================================

# Load framework (only if not already loaded)
if (-not (Get-Command -Name 'Run-Tests' -ErrorAction SilentlyContinue))
{
    $repoRoot = git rev-parse --show-toplevel 2> $null
    . (Join-Path $repoRoot "tests" "framework" "Core.ps1")
}

# ============================================================================
# RUN TESTS
# ============================================================================

Run-DirectoryCompileTests -DirectoryPath "tests/jobs"