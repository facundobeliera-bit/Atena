# CANDIDATE / NOT RUN. No user provisioning or administrative credentials.
# Requires separately approved migration + isolated fictitious fixtures.
param([switch]$ExecuteApprovedWrites, [switch]$CompleteRevocationChecks)
$ErrorActionPreference = 'Stop'
if (-not $ExecuteApprovedWrites) { throw 'Candidate disabled. Separate remote-write approval required.' }
# Tokens/fixture mapping supplied only in the process environment, never a file.
try { $c = $env:ATENA_CATALOG_TEST_CONTEXT | ConvertFrom-Json }
catch { throw 'Invalid fixture JSON. Details suppressed to protect session tokens.' }
if (-not $c -or $c.Url -ne 'https://eaegvxxxkvhdukbkydvy.supabase.co' -or
    $c.PublicKey -notlike 'sb_publishable_*' -or
    $c.InstitutionA -notmatch '^atena-pilot-catalog-' -or
    $c.InstitutionB -notmatch '^atena-pilot-catalog-') { throw 'Invalid isolated pilot fixture.' }
foreach ($field in @('TokenA','TokenOperatorA','TokenReadOnlyA','TokenB','AreaA','AreaOther',
    'PublicInstitutionA','PublicAreaA','OperatorA')) {
  if (-not $c.$field) { throw 'Incomplete fictitious fixture.' }
}
function Api([string]$Method,[string]$Path,[string]$Token,$Body=$null) {
  $headers=@{apikey=$c.PublicKey}; if ($Token) { $headers.Authorization="Bearer $Token" }
  $requestArgs=@{Method=$Method;Uri="$($c.Url)$Path";Headers=$headers;ErrorAction='Stop'}
  if ($null -ne $Body) { $requestArgs.ContentType='application/json'; $requestArgs.Body=ConvertTo-Json -InputObject $Body -Depth 30 -Compress }
  try { return @{ Status=200; Data=(Invoke-RestMethod @requestArgs); Code='' } }
  catch {
    $status=0; $code=''
    if ($_.Exception.Response) { $status=[int]$_.Exception.Response.StatusCode }
    try { $code=($_.ErrorDetails.Message | ConvertFrom-Json).code } catch { }
    return @{Status=$status;Code=$code;Data=$null} # Never log raw bodies, tokens or headers.
  }
}
function Check([bool]$ok,[string]$label) { if (-not $ok) { throw "FAIL: $label" }; Write-Output "PASS: $label" }
function Hash([string]$text) {
  $sha=[Security.Cryptography.SHA256]::Create()
  try { return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text)))).Replace('-','').ToLowerInvariant() }
  finally { $sha.Dispose() }
}
function Envelope($doc,[long]$version,[string]$state='published') {
  $payload=ConvertTo-Json -InputObject $doc -Depth 30 -Compress
  return @{p_institution_id=$c.InstitutionA;p_area_id=$c.AreaA;
    p_operation_id=([guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N'));
    p_expected_version=$version;p_fingerprint=(Hash $payload);p_payload=$payload;p_state=$state}
}
function Publish($body,[string]$token) { return Api 'POST' '/rest/v1/rpc/atena_publish_catalog' $token $body }
function PublicRead { return Api 'GET' "/rest/v1/atena_catalog_publications?area_id=eq.$($c.PublicAreaA)" '' }
function Denied($result,[string]$label) { Check ($result.Status -eq 403 -and $result.Code -eq '42501') $label }

$status=Api 'POST' '/rest/v1/rpc/atena_catalog_status' $c.TokenA @{p_institution_id=$c.InstitutionA;p_area_id=$c.AreaA}
Check ($status.Status -eq 200) 'authorized scope status'
$doc=@{schema_version=2;institution=@{id=$c.PublicInstitutionA;name='Institución ficticia';city='Ciudad piloto';province='Provincia piloto';country='Argentina'};
  area=@{id=$c.PublicAreaA;name='Área ficticia';kind='curricular'};activities=@();
  groups=@(@{id=('atena_'+(Hash 'candidate-fictitious-group'));kind='curricular';name='Grupo ficticio';activity_label='Primaria';
    schedule='08:00–12:00';capacity=10;occupied=2;available=8;availability='available';status='disponible'})}
$first=Envelope $doc $status.Data.version
$a=Publish $first $c.TokenA
Check ($a.Status -eq 200 -and $a.Data.version -eq $status.Data.version+1) 'A: institution publishes'
$again=Publish $first $c.TokenA
Check ($again.Status -eq 200 -and $again.Data.version -eq $a.Data.version) 'H: exact retry does not increment version'
$next=Envelope $doc $a.Data.version
$b=Publish $next $c.TokenOperatorA
Check ($b.Status -eq 200 -and $b.Data.version -eq $a.Data.version+1) 'B: independent authorized operator updates'
Denied (Publish (Envelope $doc $b.Data.version) $c.TokenReadOnlyA) 'C: operator without capability denied'
Denied (Publish (Envelope $doc $b.Data.version) $c.TokenB) 'D: institution B cannot modify A'
$other=Envelope $doc $b.Data.version; $other.p_area_id=$c.AreaOther
Denied (Publish $other $c.TokenOperatorA) 'E: manipulated area denied'
$read=PublicRead
Check ($read.Status -eq 200 -and @($read.Data).Count -eq 1) 'F: anonymous family can read published catalog only'
$secret=@{ schema_version=$doc.schema_version;institution=$doc.institution;area=$doc.area;activities=$doc.activities;groups=$doc.groups;password='FICTIONAL_FORBIDDEN_MARKER' }
$bad=Publish (Envelope $secret $b.Data.version) $c.TokenA
Check ($bad.Status -eq 400 -and $bad.Code -eq '22023') 'G: forbidden DTO field rejected server-side'
$private=Api 'GET' '/rest/v1/atena_pilot_operators?select=*' ''
Check ($private.Status -in @(401,403)) 'G: anonymous identity records unavailable'
$direct=Api 'POST' '/rest/v1/atena_catalog_publications' $c.TokenA @{institution_id=$c.PublicInstitutionA;area_id=$c.PublicAreaA;document=$doc;version=500;publication_state='published'}
Check ($direct.Status -eq 403) 'direct table writes denied'
$stale=Publish (Envelope $doc $a.Data.version) $c.TokenA
Check ($stale.Status -eq 409 -and $stale.Code -eq 'PT409') 'I: stale version rejected, classify by explicit conflict code'
$withdraw=Publish (Envelope $doc $b.Data.version 'withdrawn') $c.TokenA
Check ($withdraw.Status -eq 200 -and @( (PublicRead).Data ).Count -eq 0) 'F: withdrawn catalog hidden'
$doc.groups=@()
$empty=Publish (Envelope $doc $withdraw.Data.version) $c.TokenA
$read=PublicRead
Check ($empty.Status -eq 200 -and $read.Status -eq 200 -and @($read.Data).Count -eq 1 -and @($read.Data[0].document.groups).Count -eq 0) 'K: confirmed empty differs from absence/error'

$note=Api 'POST' '/rest/v1/rpc/atena_pilot_record_note' $c.TokenA @{
  p_institution_id=$c.InstitutionA;p_area_id=$c.AreaA;p_operator_id=$c.OperatorA;
  p_resource_id='catalog-regression-fictional';p_note='Fictitious regression note'}
Check ($note.Status -eq 200) 'L: previous pilot write still authorized'
$notes=Api 'GET' "/rest/v1/atena_pilot_operations?institution_id=eq.$($c.InstitutionA)&area_id=eq.$($c.AreaA)" $c.TokenA
Check ($notes.Status -eq 200 -and @($notes.Data | Where-Object { $_.id -eq $note.Data }).Count -eq 1) 'L: previous pilot reads its new note'

if ($CompleteRevocationChecks) {
  $null=Read-Host 'Authorized administrator: revoke ONLY the fictitious link of A, keep TokenA unchanged; press Enter'
  Denied (Publish (Envelope $doc $empty.Data.version) $c.TokenA) 'J1: revoked link rejects existing token'
  $null=Read-Host 'Authorized administrator: deactivate ONLY the area assignment of OperatorA; press Enter'
  Denied (Publish (Envelope $doc $empty.Data.version) $c.TokenOperatorA) 'J2: revoked assignment rejects existing token'
} else { Write-Output 'NOT RUN: J1/J2 require separately authorized fixture revocation. Do not declare full PASS.' }
Write-Output 'Candidate run finished. Full acceptance also requires the original 29 checks and two-connection race tests.'
