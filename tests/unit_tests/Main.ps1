# Configuration for pipeline YAML compilation tests
$PipelineId = "1576"
$Organisation = "ukhydro"
$ProjectName = "DevOps Chapter"

# Test 1: Expect failure due to invalid YAML key
Write-Host "=== Test 1: Invalid YAML Key ===" -ForegroundColor Cyan
$yaml1 = @"
trigger:
  - main
"error how about you go in the off direction": error
pool:
  vmImage: 'ubuntu-latest'
steps:
  - script: echo Hello, world!
"@

$testResult1 = .\scripts\Test-PipelineYaml.ps1 `
  -YamlContent $yaml1 `
  -Organization $Organisation `
  -Project $ProjectName `
  -PipelineId $PipelineId `
  -ExpectSuccess $false `
  -ExpectStatusCode 400 `
  -ExpectMessageContains "error how about you go in the off direction" `
  -TestName "Invalid YAML Key Test"

if ($testResult1.passed)
{
  Write-Host "✓ PASSED: Pipeline YAML is valid" -ForegroundColor Green
}
else
{
  Write-Host "✗ FAILED: $( $testResult1.message )" -ForegroundColor Red
  $testResult1.details | ForEach-Object { Write-Host "  - $_" }
}

Write-Host ""

# Test 2: Expect successful compilation
Write-Host "=== Test 2: Valid Pipeline YAML ===" -ForegroundColor Cyan
$yaml2 = @"
trigger:
  - main
pool:
  vmImage: 'ubuntu-latest'
steps:
  - script: echo Hello, world!
"@

$testResult2 = .\scripts\Test-PipelineYaml.ps1 `
  -YamlContent $yaml2 `
  -Organization $Organisation `
  -Project $ProjectName `
  -PipelineId $PipelineId `
  -ExpectSuccess $true `
  -TestName "Valid Pipeline Test"

if ($testResult2.passed)
{
  Write-Host "✓ PASSED: Pipeline YAML is valid" -ForegroundColor Green
}
else
{
  Write-Host "✗ FAILED: $( $testResult2.message )" -ForegroundColor Red
  $testResult2.details | ForEach-Object { Write-Host "  - $_" }
}

