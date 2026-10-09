-- Existing temporary document contract: PDF/PNG/JPEG <=2 MiB, five-day access.
-- Private pilot storage in PostgreSQL, accessed only through authorized RPCs.
-- No public URL, bucket, Auth change, historical import or commercial activation.
begin;
alter table public.atena_pilot_assignments drop constraint atena_pilot_assignments_capabilities_education_check;
alter table public.atena_pilot_assignments add constraint atena_pilot_assignments_capabilities_documents_check check
 (capabilities <@ array['pilot.read','pilot.write','catalog.publish','requests.read','requests.decide','calendar.read','calendar.write','communications.write','responses.read','education.read','education.write','documents.read','documents.write']::text[]);
create table atena_private.document_requests (
 id uuid primary key,
 request_id uuid not null references public.atena_requests(id),
 institution_id text not null,
 area_id text not null,
 profile_id text not null references atena_private.applicant_links(profile_id),
 kind text not null check(kind in ('dni','partidaNacimiento','constanciaCuil','certificadoDomicilio','libretaSanitaria','boletin','otro')),
 message text not null check(length(message)<=4000),
 state text not null default 'pendiente' check(state in ('pendiente','cumplida','cancelada')),
 created_at timestamptz not null default now(),
 operator_id text not null,
 foreign key(institution_id,area_id) references public.atena_pilot_areas(institution_id,id),
 foreign key(institution_id,operator_id) references public.atena_pilot_operators(institution_id,id)
);
create unique index document_pending_kind on atena_private.document_requests(request_id,kind) where state='pendiente';
create table atena_private.document_files (
 id uuid primary key references atena_private.document_requests(id),
 content bytea,
 mime text not null check(mime in ('application/pdf','image/png','image/jpeg')),
 fingerprint text not null,
 uploaded_at timestamptz not null default now(),
 expires_at timestamptz not null default(now()+interval '5 days'),
 deleted boolean not null default false,
 check(content is null or octet_length(content) between 1 and 2097152),
 check(not deleted or content is null)
);
create table atena_private.document_audit (
 id bigint generated always as identity primary key,
 request_id uuid not null references atena_private.document_requests(id),
 actor uuid not null references auth.users(id),
 action text not null check(action in ('requested','uploaded','cancelled','deleted','expired')),
 created_at timestamptz not null default now()
);
alter table atena_private.document_requests enable row level security;
alter table atena_private.document_files enable row level security;
alter table atena_private.document_audit enable row level security;
revoke all on atena_private.document_requests,atena_private.document_files,atena_private.document_audit from public,anon,authenticated;
revoke all on sequence atena_private.document_audit_id_seq from public,anon,authenticated;

-- Generic inbox notice, no private grade, sanction, document content or URL.
create function atena_private.shared_notice(p_id uuid,p_institution text,p_area text,p_profile text,p_request uuid,p_operator text,p_title text,p_body text)
returns void language plpgsql set search_path='' as $$
begin
 insert into atena_private.institutional_emissions(id,institution_id,area_id,kind,title,body,revision,created_by_operator_id,updated_by_operator_id)
 values(p_id,p_institution,p_area,'communication',p_title,p_body,1,p_operator,p_operator);
 insert into atena_private.emission_recipients(emission_id,profile_id,request_id) values(p_id,p_profile,p_request);
end; $$;
revoke all on function atena_private.shared_notice(uuid,text,text,text,uuid,text,text,text) from public,anon,authenticated;
create function atena_private.education_notice() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.visible_student then
  perform atena_private.shared_notice(gen_random_uuid(),new.institution_id,new.area_id,new.profile_id,new.request_id,new.updated_by_operator_id,
    'Actualización educativa','Tu institución compartió una actualización. Consultá tu trayectoria educativa.');
 end if;
 return new;
end; $$;
revoke all on function atena_private.education_notice() from public,anon,authenticated;
create trigger education_notice after insert or update on atena_private.education_records for each row execute function atena_private.education_notice();

create function atena_private.document_authorized(p_id uuid,p_write boolean default false)
returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from atena_private.document_requests d join public.atena_requests r on r.id=d.request_id
 join atena_private.applicant_links l on l.profile_id=d.profile_id and l.auth_user_id=r.applicant_auth_user_id and l.active
 where d.id=p_id and r.state='confirmed' and r.institution_id=d.institution_id and r.area_id=d.area_id
 and atena_private.request_actor(d.institution_id,d.area_id,case when p_write then 'documents.write' else 'documents.read' end) is not null);
$$;
revoke all on function atena_private.document_authorized(uuid,boolean) from public,anon,authenticated;
create function public.atena_document_request(p_institution text,p_area text,p_request uuid,p_id uuid,p_kind text,p_message text)
returns uuid language plpgsql security definer set search_path='' as $$
declare actor text; r public.atena_requests%rowtype; old atena_private.document_requests%rowtype;
begin
 actor:=atena_private.request_actor(p_institution,p_area,'documents.write');
 if actor is null then raise exception 'Document area not authorized' using errcode='42501'; end if;
 if p_id is null or p_message is null or length(p_message)>4000 or p_kind is null or p_kind not in ('dni','partidaNacimiento','constanciaCuil','certificadoDomicilio','libretaSanitaria','boletin','otro') then
  raise exception 'Invalid document request' using errcode='22023'; end if;
 select * into r from public.atena_requests where id=p_request for share;
 if r.id is null or r.state<>'confirmed' or r.institution_id<>p_institution or r.area_id<>p_area or not exists(
   select 1 from atena_private.applicant_links l where l.profile_id=r.applicant_profile_id and l.auth_user_id=r.applicant_auth_user_id and l.active) then
  raise exception 'Enrollment not authorized' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,4));
 select * into old from atena_private.document_requests where id=p_id;
 if found then
  if old.institution_id<>p_institution or old.area_id<>p_area or old.request_id<>p_request or old.kind<>p_kind or old.message<>p_message or old.operator_id<>actor then
    raise exception 'Document operation conflict' using errcode='PT409'; end if;
  return p_id;
 end if;
 insert into atena_private.document_requests(id,request_id,institution_id,area_id,profile_id,kind,message,operator_id)
 values(p_id,p_request,p_institution,p_area,r.applicant_profile_id,p_kind,p_message,actor);
 insert into atena_private.document_audit(request_id,actor,action) values(p_id,auth.uid(),'requested');
 perform atena_private.shared_notice(gen_random_uuid(),p_institution,p_area,r.applicant_profile_id,p_request,actor,
  'Documentación solicitada','Tu institución solicitó documentación. Consultá Documentos.');
 return p_id;
end; $$;
create function public.atena_documents_read(p_profile text default null,p_institution text default null,p_area text default null)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare requests jsonb; docs jsonb;
begin
 if p_profile is not null then
  if p_institution is not null or p_area is not null or not atena_private.request_is_applicant(p_profile) then raise exception 'Profile not authorized' using errcode='42501'; end if;
 else
  if atena_private.request_actor(p_institution,p_area,'documents.read') is null then raise exception 'Document area not authorized' using errcode='42501'; end if;
 end if;
 select coalesce(jsonb_agg(jsonb_build_object('id',d.id,'institucionId',d.institution_id,'areaId',d.area_id,'perfilId',d.profile_id,
   'tipo',d.kind,'mensaje',d.message,'createdAt',d.created_at,'estado',d.state,
   'ownerAccountId',case when p_profile is not null then auth.uid()::text else '' end) order by d.created_at),'[]'::jsonb) into requests
 from atena_private.document_requests d where (p_profile is not null and d.profile_id=p_profile) or
  (p_profile is null and d.institution_id=p_institution and d.area_id=p_area and atena_private.document_authorized(d.id));
 select coalesce(jsonb_agg(jsonb_build_object('id',f.id,'institucionSolicitanteId',d.institution_id,'perfilId',d.profile_id,'tipo',d.kind,
  'solicitudId',d.id,'uploadedAt',f.uploaded_at,'expiresAt',f.expires_at,'estado',case when f.expires_at<=now() then 'expirado' else 'activo' end,
  'ownerAccountId',case when p_profile is not null then auth.uid()::text else '' end) order by f.uploaded_at),'[]'::jsonb) into docs
 from atena_private.document_files f join atena_private.document_requests d on d.id=f.id where not f.deleted and
 ((p_profile is not null and d.profile_id=p_profile) or (p_profile is null and d.institution_id=p_institution and d.area_id=p_area and atena_private.document_authorized(d.id)));
 return jsonb_build_object('requests',requests,'documents',docs);
end; $$;
create function public.atena_document_upload(p_profile text,p_id uuid,p_base64 text)
returns uuid language plpgsql security definer set search_path='' as $$
declare d atena_private.document_requests%rowtype; f atena_private.document_files%rowtype; bytes bytea; mime text; fingerprint text;
begin
 if not atena_private.request_is_applicant(p_profile) then raise exception 'Profile not authorized' using errcode='42501'; end if;
 select * into d from atena_private.document_requests where id=p_id and profile_id=p_profile for update;
 if d.id is null or not exists(select 1 from public.atena_requests r where r.id=d.request_id and r.state='confirmed') then
  raise exception 'Document request not authorized' using errcode='42501'; end if;
 if p_base64 is null or length(p_base64)>2796204 then raise exception 'Invalid document size' using errcode='22023'; end if;
 bytes:=decode(p_base64,'base64');
 if octet_length(bytes) not between 1 and 2097152 then raise exception 'Invalid document size' using errcode='22023'; end if;
 mime:=case when substring(bytes from 1 for 5)=decode('255044462d','hex') then 'application/pdf'
 when substring(bytes from 1 for 8)=decode('89504e470d0a1a0a','hex') then 'image/png'
 when substring(bytes from 1 for 3)=decode('ffd8ff','hex') then 'image/jpeg' end;
 if mime is null then raise exception 'Invalid document content type' using errcode='22023'; end if;
 fingerprint:=encode(sha256(bytes),'hex');
 select * into f from atena_private.document_files where id=p_id;
 if found then
  if f.fingerprint<>fingerprint or f.deleted or f.expires_at<=now() then raise exception 'Document already supplied' using errcode='PT409'; end if;
  return p_id;
 end if;
 if d.state<>'pendiente' then raise exception 'Document request no longer pending' using errcode='PT409'; end if;
 insert into atena_private.document_files(id,content,mime,fingerprint) values(p_id,bytes,mime,fingerprint);
 update atena_private.document_requests set state='cumplida' where id=p_id;
 insert into atena_private.document_audit(request_id,actor,action) values(p_id,auth.uid(),'uploaded');
 return p_id;
end; $$;
create function public.atena_document_open(p_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare d atena_private.document_requests%rowtype; f atena_private.document_files%rowtype;
begin
 select * into d from atena_private.document_requests where id=p_id;
 if d.id is null or (not atena_private.request_is_applicant(d.profile_id) and not atena_private.document_authorized(p_id)) then
   raise exception 'Document not authorized' using errcode='42501'; end if;
 select * into f from atena_private.document_files where id=p_id and not deleted and expires_at>now() and content is not null;
 if f.id is null then raise exception 'Document unavailable or expired' using errcode='PT404'; end if;
 return jsonb_build_object('id',f.id,'mime',f.mime,'base64',encode(f.content,'base64'),
 'institucionSolicitanteId',d.institution_id,'perfilId',d.profile_id,'tipo',d.kind,'solicitudId',d.id,
 'uploadedAt',f.uploaded_at,'expiresAt',f.expires_at,'estado','activo',
 'ownerAccountId',case when atena_private.request_is_applicant(d.profile_id) then auth.uid()::text else '' end);
end; $$;
create function public.atena_document_cancel(p_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare d atena_private.document_requests%rowtype;
begin
 if not atena_private.document_authorized(p_id,true) then raise exception 'Document not authorized' using errcode='42501'; end if;
 select * into d from atena_private.document_requests where id=p_id for update;
 if d.state='cancelada' then return; end if;
 if d.state<>'pendiente' then raise exception 'Document already fulfilled' using errcode='PT409'; end if;
 update atena_private.document_requests set state='cancelada' where id=p_id;
 insert into atena_private.document_audit(request_id,actor,action) values(p_id,auth.uid(),'cancelled');
end; $$;
create function public.atena_documents_remove(p_profile text,p_id uuid default null,p_expired_only boolean default false)
returns integer language plpgsql security definer set search_path='' as $$
declare affected integer;
begin
 if not atena_private.request_is_applicant(p_profile) then raise exception 'Profile not authorized' using errcode='42501'; end if;
 if p_expired_only is null or (not p_expired_only and p_id is null) then raise exception 'Missing document' using errcode='22023'; end if;
 if p_id is not null and not exists(select 1 from atena_private.document_requests where id=p_id and profile_id=p_profile) then
   raise exception 'Document not authorized' using errcode='42501'; end if;
 with changed as (
  update atena_private.document_files f set content=null,deleted=true from atena_private.document_requests d
   where f.id=d.id and d.profile_id=p_profile and not f.deleted and
    ((p_expired_only and f.expires_at<=now()) or (not p_expired_only and f.id=p_id)) returning f.id
 ) insert into atena_private.document_audit(request_id,actor,action)
 select id,auth.uid(),case when p_expired_only then 'expired' else 'deleted' end from changed;
 get diagnostics affected=row_count;
 return affected;
end; $$;
create function public.atena_document_enrollments(p_institution text,p_area text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if atena_private.request_actor(p_institution,p_area,'documents.read') is null then
    raise exception 'Educational area not authorized' using errcode='42501'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'profile_id',r.applicant_profile_id,'group_id',r.group_id,'kind',g.kind,'created_at',r.created_at,'updated_at',r.updated_at) order by r.id),'[]'::jsonb)
    from public.atena_requests r join atena_private.request_resources g on g.group_id=r.group_id
    join atena_private.applicant_links l on l.profile_id=r.applicant_profile_id and l.auth_user_id=r.applicant_auth_user_id and l.active
    where r.institution_id=p_institution and r.area_id=p_area and r.state='confirmed');
end; $$;
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
        s.public_institution_id, s.public_area_id,
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
      join atena_private.catalog_scopes s
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



create or replace function public.atena_emission_save(p_institution text,p_area text,p_id uuid,
  p_operation uuid,p_revision integer,p_kind text,p_title text,p_body text,
  p_requests uuid[],p_group text default null,p_start timestamp default null,
  p_end timestamp default null,p_special text default 'otro',p_rsvp text default 'none',
  p_active boolean default true)
returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare actor text; previous atena_private.institutional_emissions%rowtype;
  operation atena_private.emission_operations%rowtype; payload jsonb; answer jsonb;
  selected uuid[]; matched integer; caller uuid := (select auth.uid());
begin
  actor:=atena_private.request_actor(p_institution,p_area,
    case p_kind when 'calendar' then 'calendar.write' when 'communication' then 'communications.write' end);
  if actor is null then raise exception 'Area not authorized' using errcode='42501'; end if;
  if p_id is null or p_operation is null or p_revision is null or p_revision<0 or
    p_kind is null or p_kind not in ('calendar','communication') or
    p_title is null or length(btrim(p_title)) not between 1 and 240 or
    p_body is null or length(p_body)>8000 or p_active is null or
    p_special is null or p_special not in ('inicioClases','finClases','receso','inicioCiclo','finCiclo','otro') or
    p_rsvp is null or p_rsvp not in ('none','optional','mandatory_attendance','mandatory_ack') or
    (p_kind='calendar' and (p_start is null or not isfinite(p_start))) or
    (p_end is not null and (not isfinite(p_end) or p_end<p_start)) or
    (p_kind='communication' and (p_start is not null or p_end is not null or p_rsvp<>'none')) or
    coalesce(cardinality(p_requests),0) not between 1 and 500 or array_position(p_requests,null) is not null then
    raise exception 'Invalid emission' using errcode='22023';
  end if;
  selected:=array(select distinct x from unnest(p_requests) x order by x);
  payload:=jsonb_build_object('institution',p_institution,'area',p_area,'id',p_id,'revision',p_revision,
    'kind',p_kind,'title',btrim(p_title),'body',p_body,'requests',selected,'group',p_group,
    'start',p_start,'end',p_end,'special',p_special,'rsvp',p_rsvp,'active',p_active);
  -- Serialize retries and edits. No client supplied actor or owner is accepted.
  perform pg_advisory_xact_lock(hashtextextended(caller::text||p_operation::text,0));
  select * into operation from atena_private.emission_operations
    where auth_user_id=caller and operation_id=p_operation;
  if found then
    if operation.request_body<>payload then raise exception 'Operation conflict' using errcode='PT409'; end if;
    return operation.result;
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_id::text,1));
  select * into previous from atena_private.institutional_emissions where id=p_id for update;
  if found and (previous.institution_id<>p_institution or previous.area_id<>p_area or
    previous.kind<>p_kind or previous.group_id is distinct from p_group) then
    raise exception 'Emission context conflict' using errcode='42501';
  end if;
  if coalesce(previous.revision,0)<>p_revision then
    raise exception 'Revision conflict' using errcode='PT409';
  end if;
  -- Lock confirmed enrollments while validating to prevent cancellation races.
  perform 1 from public.atena_requests r where r.id=any(selected) order by r.id for share;
  select count(*) into matched from public.atena_requests r
    join atena_private.applicant_links l on l.profile_id=r.applicant_profile_id
      and l.auth_user_id=r.applicant_auth_user_id and l.active
    where r.id=any(selected) and r.state='confirmed' and r.institution_id=p_institution
      and r.area_id=p_area and (p_group is null or r.group_id=p_group);
  if matched<>cardinality(selected) and (p_active or previous.id is null) then
    raise exception 'Recipient outside confirmed enrollment' using errcode='42501';
  end if;
  if previous.id is not null and exists(
    (select request_id from atena_private.emission_recipients where emission_id=p_id
      except select unnest(selected)) union all
    (select unnest(selected) except select request_id from atena_private.emission_recipients where emission_id=p_id)) then
    raise exception 'Delivery recipients cannot be replaced' using errcode='PT409';
  end if;
  -- One delivery per profile; ambiguous duplicate enrollments must be selected once.
  if (select count(distinct applicant_profile_id) from public.atena_requests where id=any(selected))<>cardinality(selected) then
    raise exception 'Repeated recipient profile' using errcode='22023';
  end if;
  insert into atena_private.institutional_emissions(id,institution_id,area_id,group_id,kind,title,body,
    starts_at,ends_at,special_type,rsvp_policy,revision,active,created_by_operator_id,updated_by_operator_id)
  values(p_id,p_institution,p_area,p_group,p_kind,btrim(p_title),p_body,p_start,p_end,p_special,p_rsvp,1,p_active,actor,actor)
  on conflict(id) do update set title=excluded.title,body=excluded.body,starts_at=excluded.starts_at,
    ends_at=excluded.ends_at,special_type=excluded.special_type,rsvp_policy=excluded.rsvp_policy,
    active=excluded.active,revision=previous.revision+1,updated_by_operator_id=actor,updated_at=now();
  insert into atena_private.emission_recipients(emission_id,profile_id,request_id)
    select p_id,applicant_profile_id,id from public.atena_requests where id=any(selected)
    on conflict(emission_id,profile_id) do nothing;
  insert into atena_private.emission_revisions(emission_id,revision,operator_id,auth_user_id,snapshot)
    values(p_id,p_revision+1,actor,caller,payload);
  answer:=jsonb_build_object('id',p_id,'revision',p_revision+1,'delivered',cardinality(selected));
  insert into atena_private.emission_operations(auth_user_id,operation_id,emission_id,request_body,result)
    values(caller,p_operation,p_id,payload,answer);
  return answer;
end; $$;
revoke all on function public.atena_document_request(text,text,uuid,uuid,text,text) from public,anon,authenticated;
grant execute on function public.atena_document_request(text,text,uuid,uuid,text,text) to authenticated;
revoke all on function public.atena_documents_read(text,text,text) from public,anon,authenticated;
grant execute on function public.atena_documents_read(text,text,text) to authenticated;
revoke all on function public.atena_document_upload(text,uuid,text) from public,anon,authenticated;
grant execute on function public.atena_document_upload(text,uuid,text) to authenticated;
revoke all on function public.atena_document_open(uuid) from public,anon,authenticated;
grant execute on function public.atena_document_open(uuid) to authenticated;
revoke all on function public.atena_document_cancel(uuid) from public,anon,authenticated;
grant execute on function public.atena_document_cancel(uuid) to authenticated;
revoke all on function public.atena_documents_remove(text,uuid,boolean) from public,anon,authenticated;
grant execute on function public.atena_documents_remove(text,uuid,boolean) to authenticated;
revoke all on function public.atena_document_enrollments(text,text) from public,anon,authenticated;
grant execute on function public.atena_document_enrollments(text,text) to authenticated;
commit;
