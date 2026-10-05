# Offline only: parse and execute the assertion function, NEVER the smoke runner.
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'supabase_pilot_smoke.ps1'
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($source, [ref]$tokens, [ref]$errors)
if ($errors.Count) { throw 'Smoke runner has syntax errors.' }
$function = $ast.Find({ param($node)
  $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
  $node.Name -eq 'ExpectPostgresError'
}, $true)
if (-not $function) { throw 'Missing assertion function.' }
Invoke-Expression $function.Extent.Text

ExpectPostgresError { throw 'Request failed (HTTP 400). Code: 23514.' } 'contradictory identity' 400 '23514'
ExpectPostgresError { throw 'Request failed (HTTP 409). Code: 23505.' } 'duplicate active identity' 409 '23505'
$cases = @(
  @{ Action = { }; Status = 400; Code = '23514' },
  @{ Action = { throw 'Request failed (HTTP 409). Code: 23514.' }; Status = 400; Code = '23514' },
  @{ Action = { throw 'Request failed (HTTP 400). Code: 22023.' }; Status = 400; Code = '23514' },
  @{ Action = { throw 'Request failed (HTTP 400).' }; Status = 400; Code = '23514' },
  @{ Action = { throw 'Request failed (HTTP 409). Code: 23503.' }; Status = 409; Code = '23505' },
  @{ Action = { throw 'Network unavailable' }; Status = 400; Code = '23514' }
)
foreach ($case in $cases) {
  $rejected = $false
  try { $null = ExpectPostgresError $case.Action 'must reject' $case.Status $case.Code }
  catch { $rejected = $true }
  if (-not $rejected) { throw 'Incorrect status/code was accepted.' }
}
Write-Output 'PASS: 8 offline assertion checks. No network requests.'
