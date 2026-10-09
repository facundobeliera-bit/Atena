-- LOCAL CANDIDATE: requires explicit authorization before remote application.
-- Extends the existing catalog/publication/resource model. No fixture or grants
-- to new operators. Drafts are private; published projection remains unchanged.
begin;
create table atena_private.catalog_drafts (
 institution_id text not null, area_id text not null, revision integer not null check(revision>0),
 document jsonb not null, updated_at timestamptz not null default now(),
 primary key(institution_id,area_id),
 foreign key(institution_id,area_id) references atena_private.catalog_scopes(institution_id,area_id)
);
create table atena_private.catalog_edit_operations (
 auth_user_id uuid not null references auth.users(id), operation_id uuid not null,
 payload jsonb not null, result jsonb not null, primary key(auth_user_id,operation_id)
);
alter table atena_private.catalog_drafts enable row level security;
alter table atena_private.catalog_edit_operations enable row level security;
revoke all on atena_private.catalog_drafts,atena_private.catalog_edit_operations from public,anon,authenticated;

create function public.atena_catalog_workspace(p_institution text,p_area text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare s atena_private.catalog_scopes%rowtype; d atena_private.catalog_drafts%rowtype;
 p public.atena_catalog_publications%rowtype; n text; a text; doc jsonb;
begin
 if not atena_private.catalog_can_publish(p_institution,p_area) then raise exception 'Not authorized' using errcode='42501'; end if;
 select * into s from atena_private.catalog_scopes where institution_id=p_institution and area_id=p_area;
 select * into d from atena_private.catalog_drafts where institution_id=p_institution and area_id=p_area;
 select * into p from public.atena_catalog_publications where area_id=s.public_area_id;
 select public_id into n from atena_private.catalog_namespaces where institution_id=p_institution;
 n:=coalesce(n,'atena_'||encode(sha256(convert_to('institution:'||p_institution,'UTF8')),'hex'));
 a:=coalesce(s.public_area_id,'atena_'||encode(sha256(convert_to('area:'||p_institution||':'||p_area,'UTF8')),'hex'));
 doc:=coalesce(d.document,p.document,jsonb_build_object('schema_version',3,
 'institution',jsonb_build_object('id',n,'name',(select display_name from public.atena_pilot_institutions where id=p_institution),'country','','province','','city',''),
 'area',jsonb_build_object('id',a,'name',(select display_name from public.atena_pilot_areas where institution_id=p_institution and id=p_area),'kind','curricular'),
 'activities','[]'::jsonb,'groups','[]'::jsonb));
 -- Read-only compatibility projection: never rewrite historical publications.
 if doc->>'schema_version'='2' then
  doc:=jsonb_set(jsonb_set(doc,'{schema_version}','3'),'{groups}',
   coalesce((select jsonb_agg(g || jsonb_build_object('formal_type','escolar','price','','requirements','','description','','ages','') order by ord)
    from jsonb_array_elements(doc->'groups') with ordinality as items(g,ord)),'[]'::jsonb));
 end if;
 return jsonb_build_object('institution_id',p_institution,'area_id',p_area,'revision',coalesce(d.revision,0),
 'version',coalesce(s.version,0),'publication_state',coalesce(p.publication_state,'never_published'),'document',doc);
end; $$;

create function public.atena_catalog_edit(p_institution text,p_area text,p_operation uuid,
 p_revision integer,p_version bigint,p_action text,p_document jsonb)
returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare actor text; payload jsonb; result jsonb; previous atena_private.catalog_edit_operations%rowtype;
 s atena_private.catalog_scopes%rowtype; draft atena_private.catalog_drafts%rowtype;
 doc jsonb; g jsonb; groups jsonb:='[]'; r atena_private.request_resources%rowtype;
 pool atena_private.capacity_pools%rowtype; capacity integer; occupied bigint; activity text; n text; a text;
 raw text; state text; v bigint;
begin
 -- Same live identity/owner/assignment contract as the publication RPC.
 select o.id into actor from public.atena_pilot_operators o
 join public.atena_pilot_institutions i on i.id=o.institution_id
 join public.atena_pilot_identity_links l on l.institution_id=o.institution_id and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
 join public.atena_pilot_assignments ass on ass.institution_id=o.institution_id and ass.operator_id=o.id
 join public.atena_pilot_areas ar on ar.institution_id=ass.institution_id and ar.id=ass.area_id
 where o.institution_id=p_institution and ass.area_id=p_area and o.auth_user_id=auth.uid()
 and o.active and l.active and l.revoked_at is null and ass.active and ar.active
 and (not o.is_owner or i.owner_auth_user_id=o.auth_user_id) and 'catalog.publish'=any(ass.capabilities)
 for share of o,i,l,ass,ar;
 if actor is null then raise exception 'Not authorized' using errcode='42501'; end if;
 if p_operation is null or p_revision is null or p_revision<0 or p_version is null or p_version<0 or
 p_action is null or p_action not in ('save','publish','withdraw') or p_document is null or octet_length(p_document::text)>1048576 then
 raise exception 'Invalid edit' using errcode='22023'; end if;
 payload:=jsonb_build_object('institution',p_institution,'area',p_area,'revision',p_revision,'version',p_version,'action',p_action,'document',p_document);
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text||p_operation::text,4));
 select * into previous from atena_private.catalog_edit_operations where auth_user_id=auth.uid() and operation_id=p_operation;
 if found then
  if previous.payload<>payload then raise exception 'Operation conflict' using errcode='PT409'; end if;
  return previous.result;
 end if;
 perform pg_advisory_xact_lock(hashtextextended(p_institution||':'||p_area,5));
 select * into s from atena_private.catalog_scopes where institution_id=p_institution and area_id=p_area for update;
 select public_id into n from atena_private.catalog_namespaces where institution_id=p_institution;
 n:=coalesce(n,'atena_'||encode(sha256(convert_to('institution:'||p_institution,'UTF8')),'hex'));
 insert into atena_private.catalog_namespaces values(p_institution,n) on conflict(institution_id) do nothing;
 select public_id into n from atena_private.catalog_namespaces where institution_id=p_institution;
 a:=coalesce(s.public_area_id,'atena_'||encode(sha256(convert_to('area:'||p_institution||':'||p_area,'UTF8')),'hex'));
 insert into atena_private.catalog_scopes(institution_id,area_id,public_institution_id,public_area_id)
 values(p_institution,p_area,n,a) on conflict(institution_id,area_id) do nothing;
 select * into strict s from atena_private.catalog_scopes where institution_id=p_institution and area_id=p_area for update;
 select * into draft from atena_private.catalog_drafts where institution_id=p_institution and area_id=p_area for update;
 if coalesce(draft.revision,0)<>p_revision or s.version<>p_version then raise exception 'Revision conflict' using errcode='PT409'; end if;
 doc:=p_document;
 perform atena_private.catalog_validate(doc,s.public_institution_id,s.public_area_id);
 if doc->>'schema_version'<>'3' then raise exception 'Schema 3 required' using errcode='22023'; end if;
 if exists(select 1 from jsonb_array_elements(doc->'activities') x group by x->>'name' having count(*)>1) then
 raise exception 'Ambiguous activity name' using errcode='22023'; end if;
 if p_action='publish' then
  if exists(select 1 from jsonb_array_elements(doc->'groups') x
   where trim(x->>'name')='' or trim(x->>'activity_label')='' or trim(x->>'schedule')='')
   or exists(select 1 from unnest(array['country','province','city']) k where trim(doc->'institution'->>k)='') then
   raise exception 'Publication details incomplete' using errcode='22023'; end if;
  -- Resource then pool locks, matching confirmation's order. Never overwrite
  -- occupied from a client or decrease capacity below effective occupancy.
  perform 1 from atena_private.request_resources where institution_id=p_institution and area_id=p_area order by group_id for update;
  perform 1 from atena_private.capacity_pools where institution_id=p_institution and area_id=p_area order by id for update;
  for g in select value from jsonb_array_elements(doc->'groups') loop
   select * into r from atena_private.request_resources where group_id=g->>'id';
   if r.group_id is not null and (r.institution_id<>p_institution or r.area_id<>p_area or r.kind<>g->>'kind') then
    raise exception 'Resource context cannot change' using errcode='42501'; end if;
   activity:=null;
   if g->>'kind'='extracurricular' then
    select x->>'id' into activity from jsonb_array_elements(doc->'activities') x where x->>'name'=g->>'activity_label';
    if activity is null then raise exception 'Missing activity' using errcode='22023'; end if;
    if r.group_id is not null and r.activity_public_id<>activity then raise exception 'Activity cannot be replaced' using errcode='PT409'; end if;
   end if;
   if r.group_id is not null then
    select * into strict pool from atena_private.capacity_pools where id=r.group_pool_id;
    select greatest(pool.occupied,count(*)) into occupied from public.atena_requests req where req.group_id=r.group_id and req.state='confirmed';
   else occupied:=0; end if;
   capacity:=(g->>'capacity')::integer;
   if capacity is null or capacity<occupied then raise exception 'Capacity below occupancy or unknown' using errcode='PT409'; end if;
   if r.group_id is null then
    insert into atena_private.capacity_pools(id,institution_id,area_id,kind,capacity,occupied)
    values('group:'||(g->>'id'),p_institution,p_area,'group',capacity,0);
    insert into atena_private.request_resources(group_id,institution_id,area_id,kind,group_pool_id,active,activity_public_id)
    values(g->>'id',p_institution,p_area,g->>'kind','group:'||(g->>'id'),g->>'status'<>'suspendido',activity);
   else
    update atena_private.capacity_pools cp set capacity=(g->>'capacity')::integer where cp.id=r.group_pool_id;
    update atena_private.request_resources set active=g->>'status'<>'suspendido' where group_id=r.group_id;
   end if;
   g:=g||jsonb_build_object('occupied',occupied,'available',capacity-occupied,'availability',
    case when g->>'status'='suspendido' then 'suspended' when capacity=occupied or g->>'status'='completo' then 'full' else 'available' end);
   groups:=groups||jsonb_build_array(g);
  end loop;
  update atena_private.request_resources rr set active=false where rr.institution_id=p_institution and rr.area_id=p_area
   and not exists(select 1 from jsonb_array_elements(doc->'groups') x where x->>'id'=rr.group_id);
  doc:=jsonb_set(doc,'{groups}',groups);
 end if;
 if p_action in ('publish','withdraw') then
  state:=case p_action when 'publish' then 'published' else 'withdrawn' end;
  -- Withdrawal does not copy unsaved data over the published projection.
  if p_action='withdraw' then
   select document into doc from public.atena_catalog_publications where area_id=s.public_area_id;
   if doc is null then raise exception 'Nothing published' using errcode='PT409'; end if;
  end if;
  raw:=doc::text;
  perform public.atena_publish_catalog(p_institution,p_area,encode(sha256(convert_to(p_operation::text,'UTF8')),'hex'),s.version,
   encode(sha256(convert_to(raw,'UTF8')),'hex'),raw,state);
 end if;
 insert into atena_private.catalog_drafts(institution_id,area_id,revision,document)
 values(p_institution,p_area,p_revision+1,case when p_action='withdraw' then p_document else doc end)
 on conflict(institution_id,area_id) do update set revision=excluded.revision,document=excluded.document,updated_at=clock_timestamp();
 result:=public.atena_catalog_workspace(p_institution,p_area);
 insert into atena_private.catalog_edit_operations values(auth.uid(),p_operation,payload,result);
 return result;
end; $$;
revoke all on function public.atena_catalog_workspace(text,text),public.atena_catalog_edit(text,text,uuid,integer,bigint,text,jsonb) from public,anon,authenticated;
grant execute on function public.atena_catalog_workspace(text,text),public.atena_catalog_edit(text,text,uuid,integer,bigint,text,jsonb) to authenticated;

create or replace function public.atena_authenticated_context()
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
        coalesce(s.public_institution_id,'') as public_institution_id, coalesce(s.public_area_id,'') as public_area_id,
        array(select c from unnest(a.capabilities) c
          where c in ('catalog.publish', 'requests.read', 'requests.decide', 'calendar.read', 'calendar.write', 'communications.write', 'responses.read', 'education.read', 'education.write', 'documents.read', 'documents.write')
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
      left join atena_private.catalog_scopes s
        on s.institution_id = a.institution_id and s.area_id = a.area_id
      where o.auth_user_id = caller
        and o.active and l.active and l.revoked_at is null
        and a.active and ar.active
        and (not o.is_owner or i.owner_auth_user_id = caller)
        and a.capabilities && array['catalog.publish', 'requests.read', 'requests.decide', 'calendar.read', 'calendar.write', 'communications.write', 'responses.read', 'education.read', 'education.write', 'documents.read', 'documents.write']::text[]
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
