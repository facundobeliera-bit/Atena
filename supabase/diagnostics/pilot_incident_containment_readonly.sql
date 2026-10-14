-- Project: eaegvxxxkvhdukbkydvy. Only the authorized fictional incident account.
-- READ ONLY; no credential values, personal data, mutations or JWT replay.
-- This query cannot prove refresh-token invalidation. Never label CLOSED from it.
select jsonb_build_object(
  'checked_at', now(),
  'identity_found', count(*) = 1,
  'auth_ban_until', max(u.banned_until),
  'auth_ban_active', bool_or(u.banned_until > now()),
  'atena_disabled', bool_and(coalesce(s.disabled, false)),
  'atena_cutoff', max(s.revoked_before),
  'auth_session_rows', (
    select count(*) from auth.sessions x
    where x.user_id = '1d7e4cbd-a9a2-4d36-9fb0-e7f201835812'::uuid
  ),
  'applicant_links', (
    select count(*) from atena_private.applicant_access a
    where a.auth_user_id = '1d7e4cbd-a9a2-4d36-9fb0-e7f201835812'::uuid
  ),
  'session_guard_definition_md5', (
    select md5(pg_get_functiondef('atena_private.session_allowed()'::regprocedure))
  ),
  'credential_invalidation_verified', false,
  'incident_closed', false,
  'next_check', case
    when count(*) <> 1 then 'STOP: identity missing or ambiguous'
    when not bool_and(coalesce(s.disabled, false)) then 'STOP: Atena containment absent'
    when bool_or(u.banned_until > now()) then 'PENDING: wait until Auth ban expiration'
    else 'PENDING: verify old credential rejection and private operations with authorized isolated Auth test'
  end
) as containment
from auth.users u
left join atena_private.session_security s on s.auth_user_id = u.id
where u.id = '1d7e4cbd-a9a2-4d36-9fb0-e7f201835812'::uuid;
