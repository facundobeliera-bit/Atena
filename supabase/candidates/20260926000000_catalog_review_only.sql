-- CANDIDATE ONLY / NOT APPLIED. Intentionally outside migrations/.
-- Requires approval, completed verified-link diagnosis and disposable DB tests.
-- No fixtures, Auth users, links, assignments or scopes are provisioned here.
begin;

-- Extend the existing capability vocabulary; grant it to NOBODY automatically.
-- Fail rather than drop an unknown/multi-column constraint.
do $$
declare v_constraint name;
begin
  select c.conname into strict v_constraint
  from pg_catalog.pg_constraint c
  where c.conrelid = 'public.atena_pilot_assignments'::regclass
    and c.contype = 'c'
    and c.conkey = array[(select a.attnum from pg_catalog.pg_attribute a
      where a.attrelid = c.conrelid and a.attname = 'capabilities')]::smallint[];
  execute format('alter table public.atena_pilot_assignments drop constraint %I', v_constraint);
end;
$$;
alter table public.atena_pilot_assignments
  add constraint atena_pilot_assignments_capabilities_catalog_check
  check (capabilities <@ array['pilot.read','pilot.write','catalog.publish']::text[]);

-- These are namespace mappings to EXISTING institutions/areas, not new identities.
-- Only a separately authorized administrator may provision verified mappings.
create table atena_private.catalog_namespaces (
  institution_id text primary key references public.atena_pilot_institutions(id),
  public_id text not null unique check (public_id ~ '^atena_[0-9a-f]{64}$'),
  unique(institution_id,public_id)
);
create table atena_private.catalog_scopes (
  institution_id text not null references atena_private.catalog_namespaces(institution_id),
  area_id text not null,
  public_institution_id text not null,
  public_area_id text not null unique check (public_area_id ~ '^atena_[0-9a-f]{64}$'),
  version bigint not null default 0 check (version >= 0),
  primary key (institution_id, area_id),
  unique(public_institution_id,public_area_id),
  foreign key (institution_id,public_institution_id)
    references atena_private.catalog_namespaces(institution_id,public_id),
  foreign key (institution_id, area_id) references public.atena_pilot_areas(institution_id,id)
);

-- This is the ONLY publicly readable table. No actor IDs, owner, auth or receipts.
create table public.atena_catalog_publications (
  institution_id text not null references atena_private.catalog_namespaces(public_id),
  area_id text primary key references atena_private.catalog_scopes(public_area_id),
  version bigint not null check (version > 0),
  publication_state text not null check (publication_state in ('published','withdrawn')),
  document jsonb not null check (jsonb_typeof(document) = 'object'),
  updated_at timestamptz not null default now(),
  foreign key (institution_id,area_id)
    references atena_private.catalog_scopes(public_institution_id,public_area_id)
);
create index atena_catalog_published_institution
  on public.atena_catalog_publications(institution_id,updated_at desc)
  where publication_state = 'published';

create table atena_private.catalog_receipts (
  institution_id text not null,
  area_id text not null,
  operation_id text not null check (operation_id ~ '^[0-9a-f]{64}$'),
  expected_version bigint not null check (expected_version >= 0),
  version bigint not null check (version = expected_version + 1),
  fingerprint text not null check (fingerprint ~ '^[0-9a-f]{64}$'),
  publication_state text not null check (publication_state in ('published','withdrawn')),
  actor uuid not null references auth.users(id),
  operator_id text not null,
  created_at timestamptz not null default now(),
  primary key (institution_id,area_id,operation_id),
  foreign key (institution_id,area_id) references atena_private.catalog_scopes(institution_id,area_id),
  foreign key (institution_id,operator_id) references public.atena_pilot_operators(institution_id,id)
);

alter table atena_private.catalog_namespaces enable row level security;
alter table atena_private.catalog_scopes enable row level security;
alter table atena_private.catalog_receipts enable row level security;
alter table public.atena_catalog_publications enable row level security;
revoke all on atena_private.catalog_namespaces, atena_private.catalog_scopes,
  atena_private.catalog_receipts, public.atena_catalog_publications from public, anon, authenticated;

create function atena_private.catalog_can_publish(p_institution text,p_area text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.atena_pilot_operators o
    join public.atena_pilot_institutions i on i.id=o.institution_id
    join public.atena_pilot_identity_links l on l.institution_id=o.institution_id
      and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
    join public.atena_pilot_assignments a on a.institution_id=o.institution_id and a.operator_id=o.id
    join public.atena_pilot_areas ar on ar.institution_id=a.institution_id and ar.id=a.area_id
    where o.institution_id=p_institution and a.area_id=p_area
      and o.auth_user_id=(select auth.uid())
      and o.active and l.active and l.revoked_at is null and a.active and ar.active
      and (not o.is_owner or i.owner_auth_user_id=o.auth_user_id)
      and 'catalog.publish'=any(a.capabilities)
  );
$$;

-- A small metadata-only predicate, not access to identity/assignment records.
create function atena_private.catalog_visible(p_public_institution text,p_public_area text)
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from atena_private.catalog_namespaces n
    join atena_private.catalog_scopes s on s.institution_id=n.institution_id
    join public.atena_pilot_areas a on a.institution_id=s.institution_id and a.id=s.area_id
    where n.public_id=p_public_institution and s.public_area_id=p_public_area and a.active
  );
$$;
revoke all on function atena_private.catalog_can_publish(text,text) from public,anon,authenticated;
revoke all on function atena_private.catalog_visible(text,text) from public,anon,authenticated;
grant usage on schema atena_private to anon;
grant execute on function atena_private.catalog_visible(text,text) to anon,authenticated;
grant select on public.atena_catalog_publications to anon,authenticated;
create policy catalog_published_read on public.atena_catalog_publications
  for select to anon,authenticated using (
    publication_state='published' and atena_private.catalog_visible(institution_id,area_id)
  );
-- No INSERT/UPDATE/DELETE policies or grants for clients. Writes only via RPC.

-- One public catalog boundary; the requests candidate adds live availability
-- to this same read operation without creating a second public data source.
create function public.atena_catalog_read(p_offset integer default 0,p_limit integer default 200)
returns setof public.atena_catalog_publications
language plpgsql stable security definer set search_path='' as $$
begin
  if p_offset is null or p_offset<0 or p_limit is null or p_limit not between 1 and 200 then
    raise exception 'Invalid page' using errcode='22023';
  end if;
  return query select p.* from public.atena_catalog_publications p
    where p.publication_state='published' and atena_private.catalog_visible(p.institution_id,p.area_id)
    order by p.area_id offset p_offset limit p_limit;
end;
$$;
revoke all on function public.atena_catalog_read(integer,integer) from public,anon,authenticated;
grant execute on function public.atena_catalog_read(integer,integer) to anon,authenticated;

-- Authorized discovery of the current version, including a withdrawn scope.
-- Does not create a scope or mark a local payload as confirmed.
create function public.atena_catalog_status(p_institution_id text,p_area_id text)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  if not atena_private.catalog_can_publish(p_institution_id,p_area_id) then
    raise exception 'Not authorized' using errcode='42501';
  end if;
  select jsonb_build_object('version',s.version,
    'publication_state',coalesce(p.publication_state,'never_published'),
    'updated_at',p.updated_at) into result
    from atena_private.catalog_scopes s
    left join public.atena_catalog_publications p on p.area_id=s.public_area_id
    where s.institution_id=p_institution_id and s.area_id=p_area_id;
  if result is null then raise exception 'Unverified catalog scope' using errcode='42501'; end if;
  return result;
end;
$$;
revoke all on function public.atena_catalog_status(text,text) from public,anon,authenticated;
grant execute on function public.atena_catalog_status(text,text) to authenticated;

create function atena_private.catalog_exact_keys(p jsonb, keys text[])
returns boolean language plpgsql immutable set search_path = '' as $$
begin
  if jsonb_typeof(p) is distinct from 'object' then return false; end if;
  return p ?& keys and not exists(select 1 from jsonb_object_keys(p) k where not(k=any(keys)));
end;
$$;
create function atena_private.catalog_strings(p jsonb, keys text[])
returns boolean language sql immutable set search_path = '' as $$
  select bool_and(jsonb_typeof(p->k)='string' and length(p->>k)<=512)
  from unnest(keys) k;
$$;

-- Allowlist, never return the operational identity models to readers.
create function atena_private.catalog_validate(p jsonb,p_inst text,p_area text)
returns void language plpgsql immutable set search_path = '' as $$
declare x jsonb; cap integer; occ integer; avail integer;
begin
  if (atena_private.catalog_exact_keys(p,array['schema_version','institution','area','activities','groups'])
      and p->'schema_version' in ('2'::jsonb,'3'::jsonb)
      and atena_private.catalog_exact_keys(p->'institution',array['id','name','city','province','country'])
      and atena_private.catalog_strings(p->'institution',array['id','name','city','province','country'])
      and p#>>'{institution,id}'=p_inst
      and atena_private.catalog_exact_keys(p->'area',array['id','name','kind'])
      and atena_private.catalog_strings(p->'area',array['id','name','kind'])
      and p#>>'{area,id}'=p_area
      and p#>>'{area,kind}' in ('curricular','extracurricular')
      and jsonb_typeof(p->'activities')='array'
      and jsonb_typeof(p->'groups')='array') is not true then
    raise exception 'Invalid public catalog' using errcode='22023';
  end if;
  if jsonb_array_length(p->'activities')>2000 or jsonb_array_length(p->'groups')>2000 then
    raise exception 'Catalog too large' using errcode='22023';
  end if;
  for x in select value from jsonb_array_elements(p->'activities') loop
    if (atena_private.catalog_exact_keys(x,array['id','name','active','schedule','description','ages','price'])
      and atena_private.catalog_strings(x,array['id','name','schedule','description','ages','price'])
      and x->>'id' ~ '^atena_[0-9a-f]{64}$' and jsonb_typeof(x->'active')='boolean') is not true then
      raise exception 'Invalid public activity' using errcode='22023';
    end if;
  end loop;
  for x in select value from jsonb_array_elements(p->'groups') loop
    if (atena_private.catalog_exact_keys(x,array['id','kind','name','activity_label','schedule',
          'capacity','occupied','available','availability','status'] ||
          case when p->'schema_version'='3'::jsonb
            then array['formal_type','price','requirements','description','ages']::text[]
            else array[]::text[] end)
      and atena_private.catalog_strings(x,array['id','kind','name','activity_label','schedule','availability','status'])
      and x->>'id' ~ '^atena_[0-9a-f]{64}$'
      and x->>'kind'=p#>>'{area,kind}'
      and ((x->>'kind'='curricular' and x->>'status' in ('disponible','completo','suspendido'))
        or (x->>'kind'='extracurricular' and x->>'status' in ('activo','suspendido')))
      and jsonb_typeof(x->'occupied')='number' and x->>'occupied' ~ '^[0-9]{1,7}$') is not true then
      raise exception 'Invalid public group' using errcode='22023';
    end if;
    if p->'schema_version'='3'::jsonb and (
      atena_private.catalog_strings(x,array['formal_type','price','requirements','description','ages'])
      and x->>'formal_type' in ('escolar','superior','universidad')) is not true then
      raise exception 'Invalid public presentation' using errcode='22023';
    end if;
    occ := (x->>'occupied')::integer;
    if x->'capacity'='null'::jsonb then
      if (x->>'kind'='extracurricular' and x->'available'='null'::jsonb
        and x->>'availability'=case when x->>'status'='suspendido' then 'suspended' else 'unmanaged' end) is not true then
        raise exception 'Unknown capacity cannot imply availability' using errcode='22023';
      end if;
    else
      if (jsonb_typeof(x->'capacity')='number' and x->>'capacity' ~ '^[0-9]{1,7}$'
        and jsonb_typeof(x->'available')='number' and x->>'available' ~ '^[0-9]{1,7}$') is not true then
        raise exception 'Invalid capacity' using errcode='22023';
      end if;
      cap := (x->>'capacity')::integer; avail := (x->>'available')::integer;
      if (cap>=occ and avail=cap-occ and x->>'availability'=
        case when x->>'status'='suspendido' then 'suspended'
        when cap=0 or avail=0 or x->>'status'='completo' then 'full' else 'available' end) is not true then
        raise exception 'Contradictory availability' using errcode='22023';
      end if;
    end if;
  end loop;
  if exists(select 1 from jsonb_array_elements(p->'groups') item group by item->>'id' having count(*)>1)
    or exists(select 1 from jsonb_array_elements(p->'activities') item group by item->>'id' having count(*)>1) then
    raise exception 'Duplicate catalog ID' using errcode='22023';
  end if;
end;
$$;
revoke all on function atena_private.catalog_exact_keys(jsonb,text[]),
  atena_private.catalog_strings(jsonb,text[]),atena_private.catalog_validate(jsonb,text,text)
  from public,anon,authenticated;

create function public.atena_publish_catalog(
  p_institution_id text, p_area_id text, p_operation_id text,
  p_expected_version bigint, p_fingerprint text, p_payload text,
  p_state text default 'published'
) returns jsonb language plpgsql volatile security definer set search_path = '' as $$
declare
  s atena_private.catalog_scopes%rowtype;
  n text; op text; r atena_private.catalog_receipts%rowtype;
  d jsonb; v bigint; ts timestamptz;
begin
  -- No operator_id parameter: derive the actor from auth.uid() and live binding.
  -- Locks serialize against revocation updates/deletes until this transaction ends.
  select o.id into op from public.atena_pilot_operators o
    join public.atena_pilot_institutions i on i.id=o.institution_id
    join public.atena_pilot_identity_links l on l.institution_id=o.institution_id
      and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
    join public.atena_pilot_assignments a on a.institution_id=o.institution_id and a.operator_id=o.id
    join public.atena_pilot_areas ar on ar.institution_id=a.institution_id and ar.id=a.area_id
    where o.institution_id=p_institution_id and a.area_id=p_area_id
      and o.auth_user_id=(select auth.uid()) and o.active and l.active
      and l.revoked_at is null and a.active and ar.active
      and (not o.is_owner or i.owner_auth_user_id=o.auth_user_id)
      and 'catalog.publish'=any(a.capabilities)
    for share of o,i,l,a,ar;
  if op is null then raise exception 'Not authorized' using errcode='42501'; end if;
  if (p_operation_id ~ '^[0-9a-f]{64}$' and p_fingerprint ~ '^[0-9a-f]{64}$'
      and p_expected_version>=0 and octet_length(p_payload)<=1048576
      and p_state in ('published','withdrawn')) is not true then
    raise exception 'Invalid request' using errcode='22023';
  end if;
  if encode(sha256(convert_to(p_payload,'UTF8')),'hex')<>p_fingerprint then
    raise exception 'Payload hash mismatch' using errcode='22023';
  end if;
  d := p_payload::jsonb;
  select * into s from atena_private.catalog_scopes
    where institution_id=p_institution_id and area_id=p_area_id for update;
  if not found then raise exception 'Unverified catalog scope' using errcode='42501'; end if;
  -- Serialize publications within the institution as well: a stable resource
  -- must not remain published in two areas after an accidental local move.
  select public_id into n from atena_private.catalog_namespaces
    where institution_id=s.institution_id for update;
  perform atena_private.catalog_validate(d,n,s.public_area_id);
  select * into r from atena_private.catalog_receipts
    where institution_id=s.institution_id and area_id=s.area_id and operation_id=p_operation_id;
  if found then
    if r.fingerprint<>p_fingerprint or r.expected_version<>p_expected_version
      or r.publication_state<>p_state then
      raise exception 'Idempotency key reused with different data' using errcode='22023';
    end if;
    v := r.version; ts := r.created_at;
  else
    if s.version<>p_expected_version then
      raise exception 'Catalog version conflict' using errcode='PT409';
    end if;
    if p_state='published' and exists (
      select 1 from public.atena_catalog_publications other
      where other.institution_id=n and other.area_id<>s.public_area_id
        and other.publication_state='published' and (
          exists(select 1 from jsonb_array_elements(other.document->'groups') old_item
            join jsonb_array_elements(d->'groups') new_item on old_item->>'id'=new_item->>'id')
          or exists(select 1 from jsonb_array_elements(other.document->'activities') old_item
            join jsonb_array_elements(d->'activities') new_item on old_item->>'id'=new_item->>'id')
        )
    ) then
      raise exception 'Resource already published in another area' using errcode='22023';
    end if;
    v := s.version+1; ts := clock_timestamp();
    insert into public.atena_catalog_publications
      (institution_id,area_id,version,publication_state,document,updated_at)
      values(n,s.public_area_id,v,p_state,d,ts)
      on conflict(area_id) do update set institution_id=excluded.institution_id,
        version=excluded.version,publication_state=excluded.publication_state,
        document=excluded.document,updated_at=excluded.updated_at;
    update atena_private.catalog_scopes set version=v
      where institution_id=s.institution_id and area_id=s.area_id;
    insert into atena_private.catalog_receipts(institution_id,area_id,operation_id,
      expected_version,version,fingerprint,publication_state,actor,operator_id,created_at)
      values(s.institution_id,s.area_id,p_operation_id,p_expected_version,v,
        p_fingerprint,p_state,(select auth.uid()),op,ts);
  end if;
  return jsonb_build_object('institution_id',s.institution_id,'area_id',s.area_id,
    'operation_id',p_operation_id,'fingerprint',p_fingerprint,'version',v,'updated_at',ts);
end;
$$;
revoke all on function public.atena_publish_catalog(text,text,text,bigint,text,text,text) from public,anon,authenticated;
grant execute on function public.atena_publish_catalog(text,text,text,bigint,text,text,text) to authenticated;
commit;
