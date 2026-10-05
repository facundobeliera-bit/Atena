param(
  [string]$ProjectRef = 'eaegvxxxkvhdukbkydvy',
  [string]$ExistingRun = '',
  [switch]$RunFlutterTest,
  [switch]$TestVerifiedLinks,
  [switch]$RunBrowserTest,
  [ValidateSet('a','b')][string]$BrowserRole = 'a',
  [switch]$BrowserAlreadyAtLogin
)

$ErrorActionPreference = 'Stop'
$base = "https://$ProjectRef.supabase.co"
$raw = pnpm dlx supabase@2.117.0 projects api-keys --project-ref $ProjectRef --output-format json --agent no
if ($LASTEXITCODE -ne 0) { throw 'Could not load pilot API keys.' }
$keys = ($raw | ConvertFrom-Json).keys
$publicKey = ($keys | Where-Object { $_.type -eq 'publishable' } | Select-Object -First 1).api_key
$adminKey = ($keys | Where-Object { $_.name -eq 'service_role' } | Select-Object -First 1).api_key
if (-not $publicKey -or -not $adminKey) { throw 'Pilot API keys unavailable.' }

function CallApi([string]$Method, [string]$Path, [string]$Key, [string]$Token, $Body) {
  $headers = @{ apikey = $Key }
  if ($Token) { $headers.Authorization = "Bearer $Token" }
  $args = @{ Method = $Method; Uri = "$base$Path"; Headers = $headers; ErrorAction = 'Stop' }
  if ($null -ne $Body) {
    $args.ContentType = 'application/json'
    $args.Body = ConvertTo-Json -InputObject $Body -Depth 12 -Compress
  }
  try {
    return Invoke-RestMethod @args
  } catch {
    $status = [int]$_.Exception.Response.StatusCode
    $detail = ''
    try {
      $problem = $_.ErrorDetails.Message | ConvertFrom-Json
      if ($problem.code) { $detail = " Code: $($problem.code)." }
      if ($problem.message) { $detail += " Message: $($problem.message)." }
    } catch { }
    throw "Remote request $Method $Path failed (HTTP $status).$detail"
  }
}

function Expect([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "FAIL: $Message" }
  Write-Output "PASS: $Message"
}

function ExpectDenied([scriptblock]$Action, [string]$Message) {
  try { $null = & $Action } catch {
    if ($_.Exception.Message -match 'HTTP (401|403)') {
      Write-Output "PASS: $Message"
      return
    }
    throw
  }
  throw "FAIL: $Message"
}

function ExpectPostgresError([scriptblock]$Action, [string]$Message, [int]$HttpStatus, [string]$SqlState) {
  try { $null = & $Action } catch {
    if ($_.Exception.Message -match ('\(HTTP ' + $HttpStatus + '\)') -and
        $_.Exception.Message -match ('Code: ' + [regex]::Escape($SqlState) + '\.')) {
      Write-Output "PASS: $Message"
      return
    }
    throw
  }
  throw "FAIL: $Message"
}

$run = if ($ExistingRun) { $ExistingRun } else { [guid]::NewGuid().ToString('N').Substring(0, 12) }
$existingUsers = if ($ExistingRun) {
  (CallApi 'GET' '/auth/v1/admin/users?page=1&per_page=1000' $adminKey $adminKey $null).users
} else { @() }
$accounts = @()
foreach ($label in @('a', 'b')) {
  $bytes = New-Object byte[] 32
  $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
  try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
  $password = [Convert]::ToBase64String($bytes)
  $email = "atena-pilot-$label-$run@example.invalid"
  if ($ExistingRun) {
    $user = @($existingUsers | Where-Object { $_.email -eq $email })[0]
    if (-not $user) { throw "Existing pilot user $label was not found." }
    $null = CallApi 'PUT' "/auth/v1/admin/users/$($user.id)" $adminKey $adminKey @{ password = $password }
  } else {
    $user = CallApi 'POST' '/auth/v1/admin/users' $adminKey $adminKey @{
      email = $email; password = $password; email_confirm = $true
    }
  }
  if (-not $user.id) { throw "Pilot user $label was not created." }
  $session = CallApi 'POST' '/auth/v1/token?grant_type=password' $publicKey '' @{
    email = $email; password = $password
  }
  Expect ([bool]$session.access_token) "user $label authenticates remotely"
  $accounts += [pscustomobject]@{
    Label = $label; UserId = $user.id; Token = $session.access_token
    Password = $password
    Institution = "atena-pilot-$label-$run"; Area = "area-$label-$run"
    Operator = "operator-$label-$run"
  }
}

if (-not $ExistingRun) { foreach ($account in $accounts) {
  $institution = @{ id = $account.Institution; owner_auth_user_id = $account.UserId; display_name = "Pilot institution $($account.Label)" }
  $area = @{ institution_id = $account.Institution; id = $account.Area; display_name = "Pilot area $($account.Label)" }
  $operator = @{ institution_id = $account.Institution; id = $account.Operator; auth_user_id = $account.UserId; display_name = "Pilot operator $($account.Label)"; is_owner = $true }
  $assignment = @{ institution_id = $account.Institution; area_id = $account.Area; operator_id = $account.Operator; responsible = $true; capabilities = @('pilot.read', 'pilot.write') }
  foreach ($entry in @(
    @{ table='atena_pilot_institutions'; row=$institution },
    @{ table='atena_pilot_areas'; row=$area },
    @{ table='atena_pilot_operators'; row=$operator },
    @{ table='atena_pilot_assignments'; row=$assignment }
  )) {
    $null = CallApi 'POST' "/rest/v1/$($entry.table)" $adminKey $adminKey $entry.row
  }
} }

foreach ($account in $accounts) {
  $other = @($accounts | Where-Object { $_.Label -ne $account.Label })[0]
  $own = @(CallApi 'GET' "/rest/v1/atena_pilot_institutions?select=id&id=eq.$($account.Institution)" $publicKey $account.Token $null | Where-Object { $null -ne $_ })
  $foreign = @(CallApi 'GET' "/rest/v1/atena_pilot_institutions?select=id&id=eq.$($other.Institution)" $publicKey $account.Token $null | Where-Object { $null -ne $_ })
  Expect (@($own | Where-Object { $_.id -eq $account.Institution }).Count -eq 1) "user $($account.Label) reads own institution"
  Expect (@($foreign | Where-Object { $_.id }).Count -eq 0) "user $($account.Label) cannot read foreign institution"
  $ownArea = @(CallApi 'GET' "/rest/v1/atena_pilot_areas?select=id&institution_id=eq.$($account.Institution)" $publicKey $account.Token $null | Where-Object { $null -ne $_ })
  $foreignArea = @(CallApi 'GET' "/rest/v1/atena_pilot_areas?select=id&institution_id=eq.$($other.Institution)" $publicKey $account.Token $null | Where-Object { $null -ne $_ })
  Expect (@($ownArea | Where-Object { $_.id -eq $account.Area }).Count -eq 1 -and @($foreignArea | Where-Object { $_.id }).Count -eq 0) "user $($account.Label) sees only own area"
  $note = CallApi 'POST' '/rest/v1/rpc/atena_pilot_record_note' $publicKey $account.Token @{
    p_institution_id = $account.Institution; p_area_id = $account.Area
    p_operator_id = $account.Operator; p_resource_id = "smoke-$run"
    p_note = "Fictitious pilot note $($account.Label)"
  }
  Expect ([bool]$note) "user $($account.Label) writes own pilot note"
  ExpectDenied {
    CallApi 'POST' '/rest/v1/rpc/atena_pilot_record_note' $publicKey $account.Token @{
      p_institution_id = $other.Institution; p_area_id = $other.Area
      p_operator_id = $other.Operator; p_resource_id = "cross-$run"; p_note = 'Forbidden'
    }
  } "user $($account.Label) cannot write as foreign operator"
  $ownNotes = @(CallApi 'GET' "/rest/v1/atena_pilot_operations?select=resource_id&institution_id=eq.$($account.Institution)" $publicKey $account.Token $null | Where-Object { $null -ne $_ })
  $foreignNotes = @(CallApi 'GET' "/rest/v1/atena_pilot_operations?select=resource_id&institution_id=eq.$($other.Institution)" $publicKey $account.Token $null | Where-Object { $null -ne $_ })
  Expect (@($ownNotes | Where-Object { $_.resource_id -eq "smoke-$run" }).Count -ge 1 -and @($foreignNotes | Where-Object { $_.resource_id }).Count -eq 0) "user $($account.Label) reads own note but not foreign note"
  $allVisible = @(CallApi 'GET' '/rest/v1/atena_pilot_institutions?select=id' $publicKey $account.Token $null)
  Expect (@($allVisible | Where-Object { $_.id -eq $other.Institution }).Count -eq 0) "user $($account.Label) cannot expose foreign institution with an unfiltered query"
  $ownOperator = @(CallApi 'GET' "/rest/v1/atena_pilot_operators?select=id,auth_user_id&institution_id=eq.$($account.Institution)" $publicKey $account.Token $null)
  $foreignOperator = @(CallApi 'GET' "/rest/v1/atena_pilot_operators?select=id,auth_user_id&institution_id=eq.$($other.Institution)" $publicKey $account.Token $null)
  Expect (@($ownOperator | Where-Object { $_.id -eq $account.Operator -and $_.auth_user_id -eq $account.UserId }).Count -eq 1 -and @($foreignOperator | Where-Object { $_.id }).Count -eq 0) "user $($account.Label) sees only own operator identity"
  $ownAssignment = @(CallApi 'GET' "/rest/v1/atena_pilot_assignments?select=area_id,operator_id&institution_id=eq.$($account.Institution)" $publicKey $account.Token $null)
  $foreignAssignment = @(CallApi 'GET' "/rest/v1/atena_pilot_assignments?select=area_id,operator_id&institution_id=eq.$($other.Institution)" $publicKey $account.Token $null)
  Expect (@($ownAssignment | Where-Object { $_.area_id -eq $account.Area -and $_.operator_id -eq $account.Operator }).Count -eq 1 -and @($foreignAssignment | Where-Object { $_.area_id }).Count -eq 0) "user $($account.Label) sees only own assignment"
  ExpectDenied {
    CallApi 'POST' '/rest/v1/atena_pilot_assignments' $publicKey $account.Token @{
      institution_id = $other.Institution; area_id = $other.Area
      operator_id = $account.Operator; capabilities = @('pilot.write')
    }
  } "user $($account.Label) cannot create assignments"
  ExpectDenied {
    CallApi 'POST' '/rest/v1/atena_pilot_operations' $publicKey $account.Token @{
      institution_id = $other.Institution; area_id = $other.Area
      operator_id = $other.Operator; auth_user_id = $account.UserId
      resource_id = "forged-$run"; note = 'Forbidden forged identity'
    }
  } "user $($account.Label) cannot insert with forged institution identity"
  $secondSession = CallApi 'POST' '/auth/v1/token?grant_type=password' $publicKey '' @{
    email = "atena-pilot-$($account.Label)-$run@example.invalid"
    password = $account.Password
  }
  $secondRead = @(CallApi 'GET' "/rest/v1/atena_pilot_operations?select=resource_id&institution_id=eq.$($account.Institution)" $publicKey $secondSession.access_token $null)
  Expect (@($secondRead | Where-Object { $_.resource_id -eq "smoke-$run" }).Count -ge 1) "user $($account.Label) reads persisted note from a second session"
  ExpectDenied {
    CallApi 'POST' '/rest/v1/atena_pilot_operations' $publicKey $account.Token @{
      institution_id = $account.Institution; area_id = $account.Area
      operator_id = $account.Operator; auth_user_id = $account.UserId
      resource_id = "direct-$run"; note = 'Forbidden direct insert'
    }
  } "user $($account.Label) cannot bypass RPC with direct insert"
}

ExpectDenied {
  CallApi 'GET' '/rest/v1/atena_pilot_institutions?select=id' $publicKey '' $null
} 'anonymous user cannot read pilot institutions'
if ($TestVerifiedLinks) {
  $a = $accounts[0]
  $b = $accounts[1]
  $linkA = @{
    auth_user_id = $a.UserId; local_account_id = "pilot-account-a-$run"
    institution_id = $a.Institution; operator_id = $a.Operator
    verification_ref = "pilot-proof-a-$run"
    verified_by = 'pilot-fixture-admin'
  }
  ExpectDenied {
    CallApi 'POST' '/rest/v1/atena_pilot_identity_links' $publicKey $a.Token $linkA
  } 'client cannot create its own verified link'
  $before = @(CallApi 'GET' '/rest/v1/atena_pilot_identity_links?select=id' $publicKey $a.Token $null | Where-Object { $_ -and $_.id })
  Expect ($before.Count -eq 0) 'unlinked account has no verified identity'
  ExpectDenied {
    CallApi 'POST' '/rest/v1/rpc/atena_pilot_record_verified_note' $publicKey $a.Token @{
      p_institution_id = $a.Institution; p_area_id = $a.Area
      p_operator_id = $a.Operator; p_resource_id = "unlinked-$run"
      p_note = 'Unlinked request must fail'
    }
  } 'unlinked account cannot write verified notes'
  $operatorCheck = @(CallApi 'GET' "/rest/v1/atena_pilot_operators?select=id,auth_user_id,is_owner,active&institution_id=eq.$($a.Institution)" $adminKey $adminKey $null | Where-Object { $_ -and $_.id })
  $institutionCheck = @(CallApi 'GET' "/rest/v1/atena_pilot_institutions?select=id,owner_auth_user_id&id=eq.$($a.Institution)" $adminKey $adminKey $null | Where-Object { $_ -and $_.id })
  Expect (@($operatorCheck | Where-Object { $_.id -eq $a.Operator -and $_.auth_user_id -eq $a.UserId -and $_.active }).Count -eq 1) 'administrator sees matching active pilot operator'
  Expect (@($institutionCheck | Where-Object { $_.owner_auth_user_id -eq $a.UserId }).Count -eq 1) 'administrator sees matching pilot owner'
  Expect ($linkA.auth_user_id -eq $a.UserId -and $linkA.institution_id -eq $a.Institution -and $linkA.operator_id -eq $a.Operator) 'link payload matches the verified pilot fixture'
  $null = CallApi 'POST' '/rest/v1/atena_pilot_identity_links' $adminKey $adminKey $linkA
  $contradictory = $linkA.Clone()
  $contradictory.institution_id = $b.Institution
  $contradictory.operator_id = $b.Operator
  $contradictory.verification_ref = "pilot-contradiction-$run"
  ExpectPostgresError {
    CallApi 'POST' '/rest/v1/atena_pilot_identity_links' $adminKey $adminKey $contradictory
  } 'server rejects a link whose Auth user contradicts the operator' 400 '23514'
  $duplicateLocal = $linkA.Clone()
  $duplicateLocal.auth_user_id = $b.UserId
  $duplicateLocal.institution_id = $b.Institution
  $duplicateLocal.operator_id = $b.Operator
  $duplicateLocal.verification_ref = "pilot-duplicate-$run"
  ExpectPostgresError {
    CallApi 'POST' '/rest/v1/atena_pilot_identity_links' $adminKey $adminKey $duplicateLocal
  } 'server rejects two active Auth identities for one local account' 409 '23505'
  $linkB = @{
    auth_user_id = $b.UserId; local_account_id = "pilot-account-b-$run"
    institution_id = $b.Institution; operator_id = $b.Operator
    verification_ref = "pilot-proof-b-$run"
    verified_by = 'pilot-fixture-admin'
  }
  $null = CallApi 'POST' '/rest/v1/atena_pilot_identity_links' $adminKey $adminKey $linkB
  $own = @(CallApi 'GET' '/rest/v1/atena_pilot_identity_links?select=id,local_account_id' $publicKey $a.Token $null | Where-Object { $_ -and $_.id })
  $foreign = @(CallApi 'GET' '/rest/v1/atena_pilot_identity_links?select=id' $publicKey $b.Token $null | Where-Object { $_ -and $_.id })
  Expect (@($own | Where-Object { $_.local_account_id -eq $linkA.local_account_id }).Count -eq 1 -and $foreign.Count -eq 1) 'two verified users read only their own links'
  $verifiedId = CallApi 'POST' '/rest/v1/rpc/atena_pilot_record_verified_note' $publicKey $a.Token @{
    p_institution_id = $a.Institution; p_area_id = $a.Area
    p_operator_id = $a.Operator; p_resource_id = "verified-$run"
    p_note = 'Fictitious verified operation'
  }
  Expect ([bool]$verifiedId) 'verified user writes with own operator and area'
  $verifiedBId = CallApi 'POST' '/rest/v1/rpc/atena_pilot_record_verified_note' $publicKey $b.Token @{
    p_institution_id = $b.Institution; p_area_id = $b.Area
    p_operator_id = $b.Operator; p_resource_id = "verified-b-$run"
    p_note = 'Fictitious second institution operation'
  }
  Expect ([bool]$verifiedBId) 'second verified user writes in own institution'
  ExpectDenied {
    CallApi 'POST' '/rest/v1/atena_pilot_verified_operations' $publicKey $a.Token @{
      institution_id = $a.Institution; area_id = $a.Area
      operator_id = $a.Operator; auth_user_id = $a.UserId
      resource_id = "bypass-$run"; note = 'Direct write must fail'
    }
  } 'verified user cannot bypass the RPC with a direct insert'
  $unassignedArea = "unassigned-$run"
  $null = CallApi 'POST' '/rest/v1/atena_pilot_areas' $adminKey $adminKey @{
    institution_id = $a.Institution; id = $unassignedArea
    display_name = 'Fictitious unassigned area'
  }
  ExpectDenied {
    CallApi 'POST' '/rest/v1/rpc/atena_pilot_record_verified_note' $publicKey $a.Token @{
      p_institution_id = $a.Institution; p_area_id = $unassignedArea
      p_operator_id = $a.Operator; p_resource_id = "unassigned-$run"
      p_note = 'Unassigned area must fail'
    }
  } 'verified operator cannot write to an unassigned area'
  ExpectDenied {
    CallApi 'POST' '/rest/v1/rpc/atena_pilot_record_verified_note' $publicKey $a.Token @{
      p_institution_id = $b.Institution; p_area_id = $b.Area
      p_operator_id = $b.Operator; p_resource_id = "forged-$run"
      p_note = 'Foreign operator must fail'
    }
  } 'verified user cannot impersonate foreign operator'
  ExpectDenied {
    CallApi 'POST' '/rest/v1/rpc/atena_pilot_record_verified_note' $publicKey $b.Token @{
      p_institution_id = $a.Institution; p_area_id = $a.Area
      p_operator_id = $a.Operator; p_resource_id = "forged-b-$run"
      p_note = 'Unlinked user must fail'
    }
  } 'another verified user cannot use the foreign identity'
  $aSeesB = @(CallApi 'GET' "/rest/v1/atena_pilot_verified_operations?select=id&resource_id=eq.verified-b-$run" $publicKey $a.Token $null | Where-Object { $_ -and $_.id })
  $bSeesA = @(CallApi 'GET' "/rest/v1/atena_pilot_verified_operations?select=id&resource_id=eq.verified-$run" $publicKey $b.Token $null | Where-Object { $_ -and $_.id })
  Expect ($aSeesB.Count -eq 0 -and $bSeesA.Count -eq 0) 'verified operations remain isolated between institutions'
  $null = CallApi 'PATCH' "/rest/v1/atena_pilot_identity_links?auth_user_id=eq.$($a.UserId)&institution_id=eq.$($a.Institution)" $adminKey $adminKey @{
    active = $false; revoked_at = [DateTime]::UtcNow.ToString('o')
  }
  $after = @(CallApi 'GET' "/rest/v1/atena_pilot_verified_operations?select=id&resource_id=eq.verified-$run" $publicKey $a.Token $null | Where-Object { $_ -and $_.id })
  Expect ($after.Count -eq 0) 'revoked link cannot read previous verified note'
  ExpectDenied {
    CallApi 'POST' '/rest/v1/rpc/atena_pilot_record_verified_note' $publicKey $a.Token @{
      p_institution_id = $a.Institution; p_area_id = $a.Area
      p_operator_id = $a.Operator; p_resource_id = "revoked-$run"
      p_note = 'Revoked request must fail'
    }
  } 'revoked link cannot write with an existing access token'
  $bAfterRevoke = @(CallApi 'GET' "/rest/v1/atena_pilot_verified_operations?select=id&resource_id=eq.verified-b-$run" $publicKey $b.Token $null | Where-Object { $_ -and $_.id })
  Expect ($bAfterRevoke.Count -eq 1) 'revoking A does not revoke B'
}
Write-Output "Pilot remote smoke complete; run id: $run"
if ($RunFlutterTest) {
  $env:ATENA_PILOT_PUBLIC_KEY = $publicKey
  $env:ATENA_PILOT_RUN = $run
  $env:ATENA_PILOT_PASSWORD_A = $accounts[0].Password
  $env:ATENA_PILOT_PASSWORD_B = $accounts[1].Password
  try {
    flutter test test/pilot_remote_live_test.dart --reporter expanded
    if ($LASTEXITCODE -ne 0) { throw 'Flutter live pilot test failed.' }
  } finally {
    Remove-Item Env:ATENA_PILOT_PUBLIC_KEY,Env:ATENA_PILOT_RUN,Env:ATENA_PILOT_PASSWORD_A,Env:ATENA_PILOT_PASSWORD_B -ErrorAction SilentlyContinue
  }
}
if ($RunBrowserTest) {
  if (-not $BrowserAlreadyAtLogin) {
    node tool/pilot_browser_cdp.mjs click 638 539
    if ($LASTEXITCODE -ne 0) { throw 'Could not open pilot browser screen.' }
  }
  $selected = @($accounts | Where-Object { $_.Label -eq $BrowserRole })[0]
  $env:PILOT_BROWSER_EMAIL = "atena-pilot-$BrowserRole-$run@example.invalid"
  $env:PILOT_BROWSER_PASSWORD = $selected.Password
  try {
    node tool/pilot_browser_cdp.mjs login
    if ($LASTEXITCODE -ne 0) { throw 'Browser pilot login failed.' }
  } finally {
    Remove-Item Env:PILOT_BROWSER_EMAIL,Env:PILOT_BROWSER_PASSWORD -ErrorAction SilentlyContinue
  }
}
