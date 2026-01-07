param(
  [string]$Path = $PSScriptRoot
)

$path = $Path
$newValue = "1.14.0"

Get-ChildItem $path -Recurse -Filter *.yml | ForEach-Object {
  $content = Get-Content $_.FullName

  $updated = $false

  for ($i = 0; $i -lt $content.Count; $i++) {
    if ($content[$i] -match '^\s*-?\s*name:\s*TerraformVersion\s*$') {
      for ($j = $i + 1; $j -lt $content.Count; $j++) {
        if ($content[$j] -match '^\s*default:\s*') {
          $indent = ($content[$j] -replace '(default:.*)$', '')
          $content[$j] = "${indent}default: '$newValue'"
          $updated = $true
          break
        }
        if ($content[$j] -match '^\s*-?\s*name:\s*') {
          break
        }
      }
    }
  }

  if ($updated) {
    Set-Content $_.FullName $content
  }
}
