-- REVIEW ONLY: apply to the fictitious pilot only after a separate remote
-- schema/grant review. No local Atena account is linked by this migration.
-- A trusted administrator provisions links after independently checking the
-- person's identity; Flutter, email and a local ID are not proof of ownership.

create unique index atena_pilot_operator_auth_identity
  on public.atena_pilot_operators (institution_id, id, auth_user_id);

create table public.atena_pilot_identity_links (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  auth_user_id uuid not null references auth.users(id),
  local_account_id text not null
    check (local_account_id ~ '^pilot-[a-z0-9_-]{4,120}$'),
  institution_id text not null,
  operator_id text not null,
  verification_ref text not null check (length(trim(verification_ref)) between 8 and 160),
  verified_by text not null check (length(trim(verified_by)) between 3 and 120),
  verified_at timestamptz not null default now(),
  active boolean not null default true,
  revoked_at timestamptz,
  foreign key (institution_id, operator_id, auth_user_id)
    references public.atena_pilot_operators(institution_id, id, auth_user_id),
  check ((active and revoked_at is null) or (not active and revoked_at is not null))
);

create unique index atena_pilot_one_active_remote_identity_per_local_account
  on public.atena_pilot_identity_links (local_account_id) where active;
create unique index atena_pilot_one_active_link_per_operator
  on public.atena_pilot_identity_links (institution_id, operator_id) where active;
create index atena_pilot_identity_links_auth_active
  on public.atena_pilot_identity_links (auth_user_id, institution_id, operator_id)
  where active;

-- An owner link must agree with the institution owner recorded by the server.
create function atena_private.pilot_validate_identity_link()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (
    select 1 from public.atena_pilot_operators o
    join public.atena_pilot_institutions i on i.id = o.institution_id
    where o.institution_id = new.institution_id
      and o.id = new.operator_id
      and o.auth_user_id = new.auth_user_id
      and o.active
      and (not o.is_owner or i.owner_auth_user_id = new.auth_user_id)
  ) then
    raise exception 'Identidad piloto contradictoria' using errcode = '23514';
  end if;
  return new;
end;
$$;
revoke all on function atena_private.pilot_validate_identity_link()
  from public, anon, authenticated;
create trigger atena_pilot_identity_link_consistency
  before insert or update of auth_user_id, institution_id, operator_id, active
  on public.atena_pilot_identity_links
  for each row execute function atena_private.pilot_validate_identity_link();

alter table public.atena_pilot_identity_links enable row level security;
revoke all on public.atena_pilot_identity_links from public, anon, authenticated;
grant select on public.atena_pilot_identity_links to authenticated;
grant select, insert, update on public.atena_pilot_identity_links to service_role;
create policy atena_pilot_identity_link_self_read
  on public.atena_pilot_identity_links for select to authenticated
  using (auth_user_id = (select auth.uid()));

-- This new circuit does not change the already validated pilot note endpoint.
-- Both the verified link and the existing live assignment are checked on each
-- request, so revoking either immediately denies new reads and writes here.
create function atena_private.pilot_verified_can(
  p_institution_id text, p_area_id text, p_operator_id text, p_capability text
)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select (select auth.uid()) is not null
    and exists (
      select 1 from public.atena_pilot_identity_links l
      where l.auth_user_id = (select auth.uid())
        and l.institution_id = p_institution_id
        and l.operator_id = p_operator_id
        and l.active
    )
    and (select atena_private.pilot_can(
      p_institution_id, p_area_id, p_capability
    ));
$$;
revoke all on function atena_private.pilot_verified_can(text, text, text, text)
  from public, anon;
grant execute on function atena_private.pilot_verified_can(text, text, text, text)
  to authenticated;

create table public.atena_pilot_verified_operations (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  institution_id text not null,
  area_id text not null,
  operator_id text not null,
  auth_user_id uuid not null references auth.users(id),
  resource_id text not null check (length(resource_id) between 1 and 120),
  note text not null check (length(note) between 1 and 200),
  created_at timestamptz not null default now(),
  foreign key (institution_id, area_id, operator_id)
    references public.atena_pilot_assignments(institution_id, area_id, operator_id)
);
alter table public.atena_pilot_verified_operations enable row level security;
revoke all on public.atena_pilot_verified_operations from public, anon, authenticated;
grant select on public.atena_pilot_verified_operations to authenticated;
grant select, insert on public.atena_pilot_verified_operations to service_role;
create policy atena_pilot_verified_operation_read
  on public.atena_pilot_verified_operations for select to authenticated
  using (atena_private.pilot_verified_can(
    institution_id, area_id, operator_id, 'pilot.read'
  ));

create function public.atena_pilot_record_verified_note(
  p_institution_id text,
  p_area_id text,
  p_operator_id text,
  p_resource_id text,
  p_note text
)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_id uuid;
begin
  if not (select atena_private.pilot_verified_can(
    p_institution_id, p_area_id, p_operator_id, 'pilot.write'
  )) then
    raise exception 'Operación no autorizada' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_resource_id, ''))) not between 1 and 120 or
     length(trim(coalesce(p_note, ''))) not between 1 and 200 then
    raise exception 'Datos de prueba inválidos' using errcode = '22023';
  end if;
  insert into public.atena_pilot_verified_operations (
    institution_id, area_id, operator_id, auth_user_id, resource_id, note
  ) values (
    p_institution_id, p_area_id, p_operator_id, (select auth.uid()),
    trim(p_resource_id), trim(p_note)
  ) returning id into v_id;
  return v_id;
end;
$$;
revoke all on function public.atena_pilot_record_verified_note(
  text, text, text, text, text
) from public, anon;
grant execute on function public.atena_pilot_record_verified_note(
  text, text, text, text, text
) to authenticated;
