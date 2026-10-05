-- REVIEW ONLY / NOT APPLIED. Requires the existing catalog candidate (schema 2/3).
-- No account provisioning, identity inference, legacy migration or automatic grants.
-- Admin must verify applicant links, resource mappings and opening occupancy.
begin;
alter table public.atena_pilot_assignments
  drop constraint atena_pilot_assignments_capabilities_catalog_check;
alter table public.atena_pilot_assignments
  add constraint atena_pilot_assignments_capabilities_requests_check
  check (capabilities <@ array['pilot.read','pilot.write','catalog.publish','requests.read','requests.decide']::text[]);

-- Server-owned commercial policy. Development default OFF; clients cannot
-- change it or provide entitlements in a request. Production activation needs
-- explicit administrative authorization and verified institution entitlements.
create table atena_private.commercial_policy (
  singleton boolean primary key default true check(singleton),
  enforcement_enabled boolean not null default false
);
insert into atena_private.commercial_policy(singleton) values(true);
create table atena_private.institution_entitlements (
  institution_id text primary key references public.atena_pilot_institutions(id),
  plan text not null check(plan in ('free','premium')),
  active boolean not null default false
);
alter table atena_private.commercial_policy enable row level security;
alter table atena_private.institution_entitlements enable row level security;
revoke all on atena_private.commercial_policy,atena_private.institution_entitlements from public,anon,authenticated;
create function atena_private.require_new_request_entitlement(p_inst text)
returns void language plpgsql volatile security definer set search_path='' as $$
declare enabled boolean; allowed text;
begin
  select enforcement_enabled into strict enabled from atena_private.commercial_policy where singleton for share;
  if not enabled then return; end if;
  select plan into allowed from atena_private.institution_entitlements
    where institution_id=p_inst and active and plan='premium' for share;
  if allowed is null then raise exception 'Digital enrollment unavailable' using errcode='42501'; end if;
end;
$$;
revoke all on function atena_private.require_new_request_entitlement(text) from public,anon,authenticated;

-- A verified profile mapping, NOT a client-created local account or credential.
create table atena_private.applicant_links (
  profile_id text primary key check(length(profile_id) between 1 and 160),
  auth_user_id uuid not null references auth.users(id),
  active boolean not null default true,
  verified_at timestamptz not null,
  unique(profile_id,auth_user_id)
);
create table atena_private.capacity_pools (
  id text primary key,
  institution_id text not null,
  area_id text not null,
  kind text not null check(kind in ('group','activity')),
  capacity integer check(capacity between 0 and 9999999),
  occupied integer not null check(occupied between 0 and 9999999),
  unique(id,institution_id,area_id),
  foreign key(institution_id,area_id) references atena_private.catalog_scopes(institution_id,area_id)
  -- Deliberately no occupied<=capacity constraint: imported overoccupancy is
  -- preserved as evidence and blocks confirmation, NEVER clamped away.
);
create table atena_private.request_resources (
  group_id text primary key check(group_id ~ '^atena_[0-9a-f]{64}$'),
  institution_id text not null,
  area_id text not null,
  kind text not null check(kind in ('curricular','extracurricular')),
  group_pool_id text not null unique,
  activity_pool_id text,
  active boolean not null default false,
  activity_public_id text,
  unique(group_id,institution_id,area_id),
  check(activity_pool_id is null or activity_pool_id<>group_pool_id),
  check((kind='curricular' and activity_public_id is null) or
    (kind='extracurricular' and activity_public_id is not null and activity_public_id ~ '^atena_[0-9a-f]{64}$')),
  foreign key(group_pool_id,institution_id,area_id) references atena_private.capacity_pools(id,institution_id,area_id),
  foreign key(activity_pool_id,institution_id,area_id) references atena_private.capacity_pools(id,institution_id,area_id),
  foreign key(institution_id,area_id) references atena_private.catalog_scopes(institution_id,area_id)
);
create table public.atena_requests (
  id uuid primary key default pg_catalog.gen_random_uuid(),
  group_id text not null,
  institution_id text not null,
  area_id text not null,
  applicant_profile_id text not null,
  applicant_auth_user_id uuid not null references auth.users(id),
  operation_id uuid not null,
  state text not null default 'pending' check(state in ('pending','confirmed','rejected','cancelled_by_student','cancelled_by_institution')),
  decided_by_auth_user_id uuid references auth.users(id),
  decided_by_operator_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(applicant_auth_user_id,operation_id),
  foreign key(group_id,institution_id,area_id) references atena_private.request_resources(group_id,institution_id,area_id),
  foreign key(applicant_profile_id,applicant_auth_user_id) references atena_private.applicant_links(profile_id,auth_user_id),
  foreign key(institution_id,decided_by_operator_id) references public.atena_pilot_operators(institution_id,id)
);
create unique index atena_request_one_active_profile_group on public.atena_requests(applicant_profile_id,group_id)
  where state in ('pending','confirmed');
create index atena_requests_group_confirmed on public.atena_requests(group_id) where state='confirmed';
create index atena_requests_area on public.atena_requests(institution_id,area_id,created_at);

alter table atena_private.applicant_links enable row level security;
alter table atena_private.capacity_pools enable row level security;
alter table atena_private.request_resources enable row level security;
alter table public.atena_requests enable row level security;
revoke all on atena_private.applicant_links,atena_private.capacity_pools,atena_private.request_resources,public.atena_requests from public,anon,authenticated;

create function atena_private.request_actor(p_inst text,p_area text,p_cap text)
returns text language sql stable security definer set search_path='' as $$
  select o.id from public.atena_pilot_operators o
  join public.atena_pilot_institutions i on i.id=o.institution_id
  join public.atena_pilot_identity_links l on l.institution_id=o.institution_id and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
  join public.atena_pilot_assignments a on a.institution_id=o.institution_id and a.operator_id=o.id
  join public.atena_pilot_areas ar on ar.institution_id=a.institution_id and ar.id=a.area_id
  where o.institution_id=p_inst and a.area_id=p_area and o.auth_user_id=(select auth.uid())
    and o.active and l.active and l.revoked_at is null and a.active and ar.active
    and (not o.is_owner or i.owner_auth_user_id=o.auth_user_id) and p_cap=any(a.capabilities);
$$;
create function atena_private.request_is_applicant(p_profile text)
returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from atena_private.applicant_links l where l.profile_id=p_profile and l.auth_user_id=(select auth.uid()) and l.active);
$$;
revoke all on function atena_private.request_actor(text,text,text),atena_private.request_is_applicant(text) from public,anon,authenticated;
grant execute on function atena_private.request_actor(text,text,text),atena_private.request_is_applicant(text) to authenticated;
grant select on public.atena_requests to authenticated;
create policy atena_requests_authorized_read on public.atena_requests for select to authenticated using (
  (applicant_auth_user_id=(select auth.uid()) and atena_private.request_is_applicant(applicant_profile_id))
  or atena_private.request_actor(institution_id,area_id,'requests.read') is not null
);

-- Always acquire capacity locks in lexical order. The same order protects
-- different groups sharing an activity-level pool. No caller supplies capacity.
create function atena_private.lock_request_capacity(p_group text,p_consume boolean)
returns void language plpgsql volatile security definer set search_path='' as $$
declare g atena_private.request_resources%rowtype; pool atena_private.capacity_pools%rowtype; n bigint; effective bigint;
begin
  select * into strict g from atena_private.request_resources where group_id=p_group;
  for pool in select * from atena_private.capacity_pools
    where id=g.group_pool_id or id=g.activity_pool_id order by id for update loop
    if (pool.id=g.group_pool_id and (pool.kind<>'group' or (g.kind='curricular' and pool.capacity is null)))
      or (pool.id=g.activity_pool_id and pool.kind<>'activity') then
      raise exception 'Invalid capacity mapping' using errcode='23514';
    end if;
    select count(*) into n from public.atena_requests r
      join atena_private.request_resources resource on resource.group_id=r.group_id
      where r.state='confirmed' and (resource.group_pool_id=pool.id or resource.activity_pool_id=pool.id);
    effective := greatest(pool.occupied,n);
    if pool.capacity is null or pool.capacity<=0 or effective>=9999999 or effective>=pool.capacity then
      raise exception 'No available capacity' using errcode='PT409';
    end if;
    if p_consume then
      update atena_private.capacity_pools set occupied=effective+1 where id=pool.id;
    end if;
  end loop;
end;
$$;
revoke all on function atena_private.lock_request_capacity(text,boolean) from public,anon,authenticated;

create function public.atena_request_create(p_profile_id text,p_group_id text,p_operation_id uuid)
returns public.atena_requests language plpgsql volatile security definer set search_path='' as $$
declare g atena_private.request_resources%rowtype; r public.atena_requests%rowtype; verified text;
begin
  if p_operation_id is null then raise exception 'Missing operation ID' using errcode='22023'; end if;
  select profile_id into verified from atena_private.applicant_links
    where profile_id=p_profile_id and auth_user_id=(select auth.uid()) and active for share;
  if verified is null then raise exception 'Unverified applicant' using errcode='42501'; end if;
  -- Serialize exact retry keys, including attempts to reuse one for another group.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended((select auth.uid())::text||p_operation_id::text,0));
  select * into r from public.atena_requests where applicant_auth_user_id=(select auth.uid()) and operation_id=p_operation_id;
  if found then
    if r.group_id<>p_group_id or r.applicant_profile_id<>p_profile_id then
      raise exception 'Operation ID reused' using errcode='22023';
    end if;
    return r;
  end if;
  select * into g from atena_private.request_resources where group_id=p_group_id and active for share;
  if not found then raise exception 'Resource unavailable' using errcode='42501'; end if;
  -- No request can target an unpublished, withdrawn, suspended or foreign group.
  perform 1 from public.atena_catalog_publications pub
    join atena_private.catalog_scopes scope on scope.public_area_id=pub.area_id
    where scope.institution_id=g.institution_id and scope.area_id=g.area_id and pub.publication_state='published'
      and exists(select 1 from jsonb_array_elements(pub.document->'groups') item
        where item->>'id'=p_group_id and item->>'kind'=g.kind and item->>'status' in ('disponible','activo'))
      and (g.kind='curricular' or exists(select 1 from jsonb_array_elements(pub.document->'activities') activity
        where activity->>'id'=g.activity_public_id and activity->'active'='true'::jsonb)) for share of pub;
  if not found then raise exception 'Resource not published' using errcode='42501'; end if;
  perform 1 from public.atena_pilot_areas where institution_id=g.institution_id and id=g.area_id and active for share;
  if not found then raise exception 'Area unavailable' using errcode='42501'; end if;
  perform atena_private.require_new_request_entitlement(g.institution_id);
  perform atena_private.lock_request_capacity(g.group_id,false);
  insert into public.atena_requests(group_id,institution_id,area_id,applicant_profile_id,applicant_auth_user_id,operation_id)
    values(g.group_id,g.institution_id,g.area_id,p_profile_id,(select auth.uid()),p_operation_id) returning * into r;
  return r;
end;
$$;

create function public.atena_request_decide(p_request_id uuid,p_state text)
returns public.atena_requests language plpgsql volatile security definer set search_path='' as $$
declare r public.atena_requests%rowtype; g atena_private.request_resources%rowtype; op text; verified text;
begin
  if p_state is null or p_state not in ('confirmed','rejected','cancelled_by_student','cancelled_by_institution') then
    raise exception 'Invalid decision' using errcode='22023';
  end if;
  select * into r from public.atena_requests where id=p_request_id;
  if not found then raise exception 'Request unavailable' using errcode='42501'; end if;
  if p_state='cancelled_by_student' then
    select profile_id into verified from atena_private.applicant_links where profile_id=r.applicant_profile_id
      and auth_user_id=(select auth.uid()) and active for share;
    if verified is null then raise exception 'Not authorized' using errcode='42501'; end if;
  else
    -- Lock live authorization rows against concurrent revocation until commit.
    select o.id into op from public.atena_pilot_operators o
      join public.atena_pilot_institutions i on i.id=o.institution_id
      join public.atena_pilot_identity_links l on l.institution_id=o.institution_id and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
      join public.atena_pilot_assignments a on a.institution_id=o.institution_id and a.operator_id=o.id
      join public.atena_pilot_areas ar on ar.institution_id=a.institution_id and ar.id=a.area_id
      where o.institution_id=r.institution_id and a.area_id=r.area_id and o.auth_user_id=(select auth.uid())
        and o.active and l.active and l.revoked_at is null and a.active and ar.active
        and (not o.is_owner or i.owner_auth_user_id=o.auth_user_id) and 'requests.decide'=any(a.capabilities)
      for share of o,i,l,a,ar;
    if op is null then raise exception 'Not authorized' using errcode='42501'; end if;
  end if;
  select * into strict r from public.atena_requests where id=p_request_id for update;
  if r.state=p_state then return r; end if;
  if r.state<>'pending' then raise exception 'Terminal request' using errcode='PT409'; end if;
  if p_state='confirmed' then
    perform 1 from atena_private.applicant_links where profile_id=r.applicant_profile_id
      and auth_user_id=r.applicant_auth_user_id and active for share;
    if not found then raise exception 'Applicant link revoked' using errcode='42501'; end if;
  end if;
  -- Resource mapping is immutable to clients; keep it fixed throughout decision.
  select * into strict g from atena_private.request_resources where group_id=r.group_id for share;
  if p_state='confirmed' and r.state='pending' then
    perform 1 from public.atena_catalog_publications pub
      join atena_private.catalog_scopes scope on scope.public_area_id=pub.area_id
      where scope.institution_id=g.institution_id and scope.area_id=g.area_id and pub.publication_state='published'
        and exists(select 1 from jsonb_array_elements(pub.document->'groups') item
          where item->>'id'=g.group_id and item->>'kind'=g.kind and item->>'status' in ('disponible','activo'))
        and (g.kind='curricular' or exists(select 1 from jsonb_array_elements(pub.document->'activities') activity
          where activity->>'id'=g.activity_public_id and activity->'active'='true'::jsonb)) for share of pub;
    if not found then raise exception 'Resource not published' using errcode='PT409'; end if;
  end if;
  perform 1 from atena_private.capacity_pools where id=g.group_pool_id or id=g.activity_pool_id order by id for update;
  if p_state='confirmed' then
    if not g.active then raise exception 'Resource suspended' using errcode='PT409'; end if;
    perform atena_private.lock_request_capacity(g.group_id,true);
  end if;
  update public.atena_requests set state=p_state,decided_by_auth_user_id=(select auth.uid()),
    decided_by_operator_id=op,updated_at=clock_timestamp() where id=r.id returning * into r;
  -- Any exception rolls back BOTH capacity and decision. No background counter.
  return r;
end;
$$;
revoke all on function public.atena_request_create(text,text,uuid),public.atena_request_decide(uuid,text) from public,anon,authenticated;
grant execute on function public.atena_request_create(text,text,uuid),public.atena_request_decide(uuid,text) to authenticated;

-- Public availability is calculated from the SAME authoritative pools used by
-- confirmation. It is advisory at read time; confirmation still locks/rechecks.
create function atena_private.catalog_live_group(p_group jsonb,p_inst text,p_area text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare g atena_private.request_resources%rowtype; pool atena_private.capacity_pools%rowtype;
  effective bigint; n bigint; remaining bigint:=9999999; result jsonb:=p_group;
begin
  select * into g from atena_private.request_resources where group_id=p_group->>'id'
    and institution_id=p_inst and area_id=p_area;
  if not found then return result || jsonb_build_object('available',null,'availability','unmanaged'); end if;
  if not g.active or p_group->>'status'='suspendido' then
    return result || jsonb_build_object('available',0,'availability','suspended');
  end if;
  if g.kind='extracurricular' and not exists (
    select 1 from public.atena_catalog_publications pub join atena_private.catalog_scopes s on s.public_area_id=pub.area_id,
      jsonb_array_elements(pub.document->'activities') activity
    where s.institution_id=p_inst and s.area_id=p_area and pub.publication_state='published'
      and activity->>'id'=g.activity_public_id and activity->'active'='true'::jsonb
  ) then return result || jsonb_build_object('available',0,'availability','suspended'); end if;
  for pool in select * from atena_private.capacity_pools where id=g.group_pool_id or id=g.activity_pool_id loop
    select count(*) into n from public.atena_requests r
      join atena_private.request_resources resource on resource.group_id=r.group_id
      where r.state='confirmed' and (resource.group_pool_id=pool.id or resource.activity_pool_id=pool.id);
    effective:=greatest(pool.occupied,n);
    if pool.id=g.group_pool_id then result:=result || jsonb_build_object('capacity',pool.capacity,'occupied',effective); end if;
    if pool.capacity is null then
      return result || jsonb_build_object('available',null,'availability','unmanaged');
    end if;
    remaining:=least(remaining,greatest(0,pool.capacity-effective));
  end loop;
  if p_group->>'status'='completo' then remaining:=0; end if;
  return result || jsonb_build_object('available',remaining,'availability',case when remaining>0 then 'available' else 'full' end);
end;
$$;
revoke all on function atena_private.catalog_live_group(jsonb,text,text) from public,anon,authenticated;

create or replace function public.atena_catalog_read(p_offset integer default 0,p_limit integer default 200)
returns setof public.atena_catalog_publications
language plpgsql stable security definer set search_path='' as $$
declare publication public.atena_catalog_publications%rowtype; scope atena_private.catalog_scopes%rowtype; groups jsonb;
begin
  if p_offset is null or p_offset<0 or p_limit is null or p_limit not between 1 and 200 then
    raise exception 'Invalid page' using errcode='22023';
  end if;
  for publication in select p.* from public.atena_catalog_publications p
    where p.publication_state='published' and atena_private.catalog_visible(p.institution_id,p.area_id)
    order by p.area_id offset p_offset limit p_limit loop
    select * into strict scope from atena_private.catalog_scopes where public_area_id=publication.area_id;
    select coalesce(jsonb_agg(atena_private.catalog_live_group(item,scope.institution_id,scope.area_id) order by ord),'[]'::jsonb)
      into groups from jsonb_array_elements(publication.document->'groups') with ordinality items(item,ord);
    publication.document:=jsonb_set(publication.document,'{groups}',groups);
    return next publication;
  end loop;
end;
$$;
commit;
