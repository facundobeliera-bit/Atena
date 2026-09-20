-- REVIEW ONLY. Do not apply before explicit approval and a schema/grant review
-- against project eaegvxxxkvhdukbkydvy. No historical Atena data is migrated.
-- Rows and Auth users are provisioned separately, after explicit approval.

create schema if not exists atena_private;
revoke all on schema atena_private from public;
grant usage on schema atena_private to authenticated;

create table public.atena_pilot_institutions (
  id text primary key check (length(id) between 1 and 120),
  owner_auth_user_id uuid not null references auth.users(id),
  display_name text not null check (length(display_name) between 1 and 160),
  created_at timestamptz not null default now()
);

create table public.atena_pilot_areas (
  institution_id text not null references public.atena_pilot_institutions(id),
  id text not null check (length(id) between 1 and 120),
  display_name text not null check (length(display_name) between 1 and 160),
  active boolean not null default true,
  primary key (institution_id, id)
);

create table public.atena_pilot_operators (
  institution_id text not null references public.atena_pilot_institutions(id),
  id text not null check (length(id) between 1 and 120),
  auth_user_id uuid not null references auth.users(id),
  display_name text not null check (length(display_name) between 1 and 160),
  is_owner boolean not null default false,
  active boolean not null default true,
  primary key (institution_id, id),
  unique (institution_id, auth_user_id)
);

create unique index atena_pilot_one_owner_per_institution
  on public.atena_pilot_operators (institution_id) where is_owner;

create table public.atena_pilot_assignments (
  institution_id text not null,
  area_id text not null,
  operator_id text not null,
  active boolean not null default true,
  responsible boolean not null default false,
  capabilities text[] not null default '{}',
  primary key (institution_id, area_id, operator_id),
  foreign key (institution_id, area_id)
    references public.atena_pilot_areas(institution_id, id),
  foreign key (institution_id, operator_id)
    references public.atena_pilot_operators(institution_id, id),
  check (capabilities <@ array['pilot.read', 'pilot.write']::text[])
);

create unique index atena_pilot_one_responsible_per_area
  on public.atena_pilot_assignments (institution_id, area_id)
  where active and responsible;

create table public.atena_pilot_operations (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  institution_id text not null,
  area_id text not null,
  operator_id text not null,
  auth_user_id uuid not null references auth.users(id),
  resource_type text not null default 'pilot_note'
    check (resource_type = 'pilot_note'),
  resource_id text not null check (length(resource_id) between 1 and 120),
  note text not null check (length(note) between 1 and 200),
  created_at timestamptz not null default now(),
  foreign key (institution_id, area_id, operator_id)
    references public.atena_pilot_assignments(institution_id, area_id, operator_id)
);

alter table public.atena_pilot_institutions enable row level security;
alter table public.atena_pilot_areas enable row level security;
alter table public.atena_pilot_operators enable row level security;
alter table public.atena_pilot_assignments enable row level security;
alter table public.atena_pilot_operations enable row level security;

-- Client roles cannot provision institutions, operators or assignments.
revoke all on public.atena_pilot_institutions,
  public.atena_pilot_areas,
  public.atena_pilot_operators,
  public.atena_pilot_assignments,
  public.atena_pilot_operations from public, anon, authenticated;
grant select on public.atena_pilot_institutions,
  public.atena_pilot_areas,
  public.atena_pilot_operations to authenticated;

create function atena_private.pilot_is_member(p_institution_id text)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select (select auth.uid()) is not null and exists (
    select 1 from public.atena_pilot_operators o
    where o.institution_id = p_institution_id
      and o.auth_user_id = (select auth.uid())
      and o.active
  );
$$;

create function atena_private.pilot_can(
  p_institution_id text, p_area_id text, p_capability text
)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select (select auth.uid()) is not null and exists (
    select 1
    from public.atena_pilot_operators o
    join public.atena_pilot_assignments a
      on a.institution_id = o.institution_id and a.operator_id = o.id
    join public.atena_pilot_areas ar
      on ar.institution_id = a.institution_id and ar.id = a.area_id
    where o.institution_id = p_institution_id
      and a.area_id = p_area_id
      and o.auth_user_id = (select auth.uid())
      and o.active and a.active and ar.active
      and p_capability = any(a.capabilities)
  );
$$;

revoke all on function atena_private.pilot_is_member(text) from public;
revoke all on function atena_private.pilot_can(text, text, text) from public;
grant execute on function atena_private.pilot_is_member(text) to authenticated;
grant execute on function atena_private.pilot_can(text, text, text)
  to authenticated;

create policy atena_pilot_institution_read
  on public.atena_pilot_institutions for select to authenticated
  using ((select atena_private.pilot_is_member(id)));
create policy atena_pilot_area_read
  on public.atena_pilot_areas for select to authenticated
  using ((select atena_private.pilot_is_member(institution_id)));
create policy atena_pilot_operation_read
  on public.atena_pilot_operations for select to authenticated
  using (atena_private.pilot_can(institution_id, area_id, 'pilot.read'));

-- The publishable key never authorizes writes by itself. An authenticated
-- user must be bound to the exact operator and its active area assignment.
create function public.atena_pilot_record_note(
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
  if (select auth.uid()) is null or
     not exists (
       select 1 from public.atena_pilot_operators o
       join public.atena_pilot_assignments a
         on a.institution_id = o.institution_id and a.operator_id = o.id
       join public.atena_pilot_areas ar
         on ar.institution_id = a.institution_id and ar.id = a.area_id
       where o.institution_id = p_institution_id
         and o.id = p_operator_id
         and o.auth_user_id = (select auth.uid())
         and a.area_id = p_area_id
         and o.active and a.active and ar.active
         and 'pilot.write' = any(a.capabilities)
     ) then
    raise exception 'Operación no autorizada' using errcode = '42501';
  end if;
  if length(trim(coalesce(p_resource_id, ''))) not between 1 and 120 or
     length(trim(coalesce(p_note, ''))) not between 1 and 200 then
    raise exception 'Datos de prueba inválidos' using errcode = '22023';
  end if;
  insert into public.atena_pilot_operations (
    institution_id, area_id, operator_id, auth_user_id, resource_id, note
  ) values (
    p_institution_id, p_area_id, p_operator_id, (select auth.uid()),
    trim(p_resource_id), trim(p_note)
  ) returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.atena_pilot_record_note(
  text, text, text, text, text
) from public, anon;
grant execute on function public.atena_pilot_record_note(
  text, text, text, text, text
) to authenticated;
