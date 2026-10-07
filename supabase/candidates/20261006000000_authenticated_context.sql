-- Pilot-only authenticated discovery. Apply AFTER catalog and requests/capacity.
-- No provisioning, historical migration, new capabilities or table grants.
-- Zero arguments: the caller cannot nominate another user or local identity.
begin;

create function public.atena_authenticated_context()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  caller uuid := (select auth.uid());
  profiles jsonb;
  contexts jsonb;
begin
  if caller is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object('profile_id', l.profile_id)
    order by l.profile_id), '[]'::jsonb)
    into profiles
    from atena_private.applicant_links l
    where l.auth_user_id = caller and l.active;

  select coalesce(jsonb_agg(jsonb_build_object(
      'institution_id', permitted.institution_id,
      'institution_name', permitted.institution_name,
      'area_id', permitted.area_id,
      'area_name', permitted.area_name,
      'operator_id', permitted.operator_id,
      'public_institution_id', permitted.public_institution_id,
      'public_area_id', permitted.public_area_id,
      'capabilities', permitted.capabilities
    ) order by permitted.institution_id, permitted.area_id), '[]'::jsonb)
    into contexts
    from (
      select o.institution_id, i.display_name as institution_name,
        a.area_id, ar.display_name as area_name, o.id as operator_id,
        s.public_institution_id, s.public_area_id,
        array(select c from unnest(a.capabilities) c
          where c in ('catalog.publish', 'requests.read', 'requests.decide')
          order by c) as capabilities
      from public.atena_pilot_operators o
      join public.atena_pilot_institutions i on i.id = o.institution_id
      join public.atena_pilot_identity_links l
        on l.institution_id = o.institution_id and l.operator_id = o.id
        and l.auth_user_id = o.auth_user_id
      join public.atena_pilot_assignments a
        on a.institution_id = o.institution_id and a.operator_id = o.id
      join public.atena_pilot_areas ar
        on ar.institution_id = a.institution_id and ar.id = a.area_id
      join atena_private.catalog_scopes s
        on s.institution_id = a.institution_id and s.area_id = a.area_id
      where o.auth_user_id = caller
        and o.active and l.active and l.revoked_at is null
        and a.active and ar.active
        and (not o.is_owner or i.owner_auth_user_id = caller)
        and a.capabilities && array['catalog.publish', 'requests.read', 'requests.decide']::text[]
    ) permitted;

  -- No local account IDs, verification records, other users or private notes.
  -- Discovery is not an authorization cache: existing RPCs revalidate every call.
  return jsonb_build_object('auth_user_id', caller,
    'applicant_profiles', profiles, 'institutional_contexts', contexts);
end;
$$;

revoke all on function public.atena_authenticated_context()
  from public, anon, authenticated;
grant execute on function public.atena_authenticated_context() to authenticated;

commit;
