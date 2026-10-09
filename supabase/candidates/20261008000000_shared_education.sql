-- Six existing educational modules; no automatic publication or identity migration.
begin;
alter table public.atena_pilot_assignments drop constraint atena_pilot_assignments_capabilities_calendar_check;
alter table public.atena_pilot_assignments add constraint atena_pilot_assignments_capabilities_education_check check
 (capabilities <@ array['pilot.read','pilot.write','catalog.publish','requests.read','requests.decide','calendar.read','calendar.write','communications.write','responses.read','education.read','education.write']::text[]);
create table atena_private.education_records (
  id text primary key check(length(id) between 1 and 200),
  request_id uuid not null references public.atena_requests(id),
  institution_id text not null,
  area_id text not null,
  profile_id text not null references atena_private.applicant_links(profile_id),
  module text not null check(module in ('progreso','boletines','titulos','becas','sanciones','equivalencias')),
  data jsonb not null,
  visible_student boolean not null default false,
  revision integer not null check(revision>0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by_operator_id text not null,
  updated_by_operator_id text not null,
  foreign key(institution_id,area_id) references public.atena_pilot_areas(institution_id,id),
  foreign key(institution_id,created_by_operator_id) references public.atena_pilot_operators(institution_id,id),
  foreign key(institution_id,updated_by_operator_id) references public.atena_pilot_operators(institution_id,id)
);
create unique index education_one_progress on atena_private.education_records(request_id) where module='progreso';
create unique index education_one_report on atena_private.education_records(request_id,(data->>'anio'),(data->>'periodo')) where module='boletines';
create table atena_private.education_revisions (
  record_id text not null references atena_private.education_records(id),
  revision integer not null,
  operator_id text not null,
  auth_user_id uuid not null references auth.users(id),
  data jsonb not null,
  visible_student boolean not null,
  created_at timestamptz not null default now(),
  primary key(record_id,revision)
);
create table atena_private.education_operations (
  auth_user_id uuid not null references auth.users(id),
  operation_id uuid not null,
  record_id text not null references atena_private.education_records(id),
  payload jsonb not null,
  result jsonb not null,
  primary key(auth_user_id,operation_id)
);
alter table atena_private.education_records enable row level security;
alter table atena_private.education_revisions enable row level security;
alter table atena_private.education_operations enable row level security;
revoke all on atena_private.education_records,atena_private.education_revisions,atena_private.education_operations from public,anon,authenticated;

create function atena_private.education_validate(p_module text,p_data jsonb)
returns jsonb language plpgsql immutable set search_path='' as $$
declare fields text[]; required text[]; dates text[]; flag text; k text; v jsonb; day date;
begin
  case p_module
  when 'progreso' then fields:=array['porcentaje']; required:='{}';
  when 'boletines' then fields:=array['anio','periodo','calificaciones','observaciones','completo']; required:=array['periodo'];
  when 'titulos' then fields:=array['titulo','entidadEmisora','fechaEmision']; required:=array['titulo','entidadEmisora']; dates:=array['fechaEmision'];
  when 'becas' then fields:=array['nombre','descripcion','fechaInicio','fechaFin','activa']; required:=array['nombre']; dates:=array['fechaInicio','fechaFin']; flag:='activa';
  when 'sanciones' then fields:=array['motivo','tipo','detalle','fecha','hasta','activa']; required:=array['motivo']; dates:=array['fecha','hasta']; flag:='activa';
  when 'equivalencias' then fields:=array['institucionOrigenId','materiaOrigen','materiaDestino','observacion','fecha','aprobada']; required:=array['institucionOrigenId','materiaOrigen','materiaDestino']; dates:=array['fecha']; flag:='aprobada';
  else raise exception 'Unknown educational module' using errcode='22023'; end case;
  if p_data is null or jsonb_typeof(p_data)<>'object' or octet_length(p_data::text)>64000 or
    exists(select 1 from jsonb_object_keys(p_data) t(k) where not t.k=any(fields)) then
    raise exception 'Unapproved educational fields' using errcode='22023'; end if;
  foreach k in array required loop
    if coalesce(jsonb_typeof(p_data->k),'null')<>'string' or length(btrim(p_data->>k))=0 then
      raise exception 'Missing educational field' using errcode='22023'; end if;
  end loop;
  for k,v in select * from jsonb_each(p_data) loop
    if jsonb_typeof(v)='string' and length(v#>>'{}')>4000 then
      raise exception 'Educational field too long' using errcode='22023'; end if;
    if not k=any(coalesce(dates,'{}')||array['porcentaje','anio','calificaciones','completo','activa','aprobada']) and jsonb_typeof(v)<>'string' then
      raise exception 'Invalid educational field type' using errcode='22023'; end if;
  end loop;
  if flag is not null and coalesce(jsonb_typeof(p_data->flag),'null')<>'boolean' then
    raise exception 'Missing boolean state' using errcode='22023'; end if;
  foreach k in array coalesce(dates,'{}') loop
    if (p_data->k is null or p_data->k='null'::jsonb) and k in ('fechaFin','hasta') then continue; end if;
    if coalesce(jsonb_typeof(p_data->k),'null')<>'string' or
      (p_data->>k)!~'^\d{4}-\d{2}-\d{2}(T00:00:00(\.000)?)?$' then
      raise exception 'Invalid educational date' using errcode='22023'; end if;
    day:=substring(p_data->>k,1,10)::date;
    if not isfinite(day) then raise exception 'Invalid educational date' using errcode='22023'; end if;
  end loop;
  if coalesce(p_data->>'fechaFin',p_data->>'hasta') is not null and
    coalesce(p_data->>'fechaFin',p_data->>'hasta')::timestamp < coalesce(p_data->>'fechaInicio',p_data->>'fecha')::timestamp then
    raise exception 'Invalid date range' using errcode='22023'; end if;
  if p_module='progreso' and (coalesce(jsonb_typeof(p_data->'porcentaje'),'null')<>'number' or
    (p_data->>'porcentaje')::numeric not between 0 and 100) then
    raise exception 'Invalid progress' using errcode='22023'; end if;
  if p_module='boletines' then
    if coalesce(jsonb_typeof(p_data->'anio'),'null')<>'number' or (p_data->>'anio')!~'^\d{4}$' or
      (p_data->>'anio')::integer not between 1900 and 2200 or coalesce(jsonb_typeof(p_data->'calificaciones'),'null')<>'object' then
      raise exception 'Invalid report card' using errcode='22023'; end if;
    for k,v in select * from jsonb_each(p_data->'calificaciones') loop
      if length(btrim(k))=0 or jsonb_typeof(v)<>'number' or (v::text)::double precision in ('Infinity'::double precision,'-Infinity'::double precision) then
        raise exception 'Invalid grade' using errcode='22023'; end if;
    end loop;
    p_data:=jsonb_set(p_data,'{completo}',to_jsonb(p_data->'calificaciones'<>'{}'::jsonb));
  end if;
  return p_data;
end; $$;
revoke all on function atena_private.education_validate(text,jsonb) from public,anon,authenticated;

create function public.atena_education_enrollments(p_institution text,p_area text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if atena_private.request_actor(p_institution,p_area,'education.read') is null then
    raise exception 'Educational area not authorized' using errcode='42501'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'profile_id',r.applicant_profile_id,'group_id',r.group_id,'kind',g.kind,'created_at',r.created_at,'updated_at',r.updated_at) order by r.id),'[]'::jsonb)
    from public.atena_requests r join atena_private.request_resources g on g.group_id=r.group_id
    join atena_private.applicant_links l on l.profile_id=r.applicant_profile_id and l.auth_user_id=r.applicant_auth_user_id and l.active
    where r.institution_id=p_institution and r.area_id=p_area and r.state='confirmed');
end; $$;

create function public.atena_education_save(p_institution text,p_area text,p_request uuid,p_id text,p_module text,
 p_operation uuid,p_revision integer,p_data jsonb,p_visible boolean)
returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare actor text; enrollment public.atena_requests%rowtype; previous atena_private.education_records%rowtype;
 operation atena_private.education_operations%rowtype; validated jsonb; payload jsonb; result jsonb; caller uuid:=(select auth.uid());
begin
 actor:=atena_private.request_actor(p_institution,p_area,'education.write');
 if actor is null or atena_private.request_actor(p_institution,p_area,'education.read') is null then
   raise exception 'Educational area not authorized' using errcode='42501'; end if;
 if p_id is null or length(p_id) not between 1 and 200 or p_operation is null or p_revision is null or p_revision<0 or p_visible is null then
   raise exception 'Invalid record' using errcode='22023'; end if;
 validated:=atena_private.education_validate(p_module,p_data);
 payload:=jsonb_build_object('institution',p_institution,'area',p_area,'request',p_request,'id',p_id,
   'module',p_module,'data',validated,'visible',p_visible,'revision',p_revision);
 perform pg_advisory_xact_lock(hashtextextended(caller::text||p_operation::text,2));
 select * into operation from atena_private.education_operations where auth_user_id=caller and operation_id=p_operation;
 if found then
   if operation.payload<>payload then raise exception 'Operation conflict' using errcode='PT409'; end if;
   return operation.result;
 end if;
 select * into enrollment from public.atena_requests where id=p_request for share;
 if enrollment.id is null or enrollment.institution_id<>p_institution or enrollment.area_id<>p_area or enrollment.state<>'confirmed'
   or not exists(select 1 from atena_private.applicant_links where profile_id=enrollment.applicant_profile_id and auth_user_id=enrollment.applicant_auth_user_id and active) then
   raise exception 'Confirmed enrollment required' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_id,3));
 select * into previous from atena_private.education_records where id=p_id for update;
 if found and (previous.request_id<>p_request or previous.module<>p_module or previous.institution_id<>p_institution or previous.area_id<>p_area) then
   raise exception 'Record belongs to another context' using errcode='42501'; end if;
 if coalesce(previous.revision,0)<>p_revision then raise exception 'Revision conflict' using errcode='PT409'; end if;
 insert into atena_private.education_records(id,request_id,institution_id,area_id,profile_id,module,data,visible_student,revision,created_by_operator_id,updated_by_operator_id)
 values(p_id,p_request,p_institution,p_area,enrollment.applicant_profile_id,p_module,validated,p_visible,1,actor,actor)
 on conflict(id) do update set data=excluded.data,visible_student=excluded.visible_student,revision=previous.revision+1,updated_at=now(),updated_by_operator_id=actor;
 insert into atena_private.education_revisions(record_id,revision,operator_id,auth_user_id,data,visible_student)
 values(p_id,p_revision+1,actor,caller,validated,p_visible);
 result:=jsonb_build_object('id',p_id,'revision',p_revision+1);
 insert into atena_private.education_operations values(caller,p_operation,p_id,payload,result);
 return result;
end; $$;

create function public.atena_education_read(p_module text,p_profile text default null,p_institution text default null,p_area text default null,p_request uuid default null)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if p_module is null or p_module not in ('progreso','boletines','titulos','becas','sanciones','equivalencias') then
   raise exception 'Unknown educational module' using errcode='22023'; end if;
 if p_profile is not null then
   if p_institution is not null or p_area is not null or p_request is not null or not atena_private.request_is_applicant(p_profile) then
     raise exception 'Profile not authorized' using errcode='42501'; end if;
 else
   if atena_private.request_actor(p_institution,p_area,'education.read') is null or not exists(
     select 1 from public.atena_requests r join atena_private.applicant_links l on l.profile_id=r.applicant_profile_id and l.auth_user_id=r.applicant_auth_user_id and l.active
     where r.id=p_request and r.institution_id=p_institution and r.area_id=p_area and r.state='confirmed') then
     raise exception 'Educational enrollment not authorized' using errcode='42501'; end if;
 end if;
 return (select coalesce(jsonb_agg(e.data || jsonb_build_object('id',e.id,'institucionId',e.institution_id,
   'institucion',i.display_name,'institucionDestinoId',e.institution_id,'perfilId',e.profile_id,
   'areaId',e.area_id,'solicitudId',e.request_id,'grupoId',r.group_id,'visibleAlumno',e.visible_student,
   'ultimaActualizacion',e.updated_at,'revision',e.revision,'operadorNombre',o.display_name) ||
   case when p_profile is null then jsonb_build_object('historial',
     (select coalesce(jsonb_agg(h.data || jsonb_build_object('revision',h.revision,'visibleAlumno',h.visible_student,
       'ultimaActualizacion',h.created_at,'institucion',i.display_name,'operadorNombre',past_actor.display_name)
       order by h.revision),'[]'::jsonb) from atena_private.education_revisions h
       join public.atena_pilot_operators past_actor on past_actor.id=h.operator_id and past_actor.institution_id=e.institution_id
       where h.record_id=e.id and h.revision<e.revision)) else '{}'::jsonb end
   order by e.created_at,e.id),'[]'::jsonb)
   from atena_private.education_records e join public.atena_pilot_institutions i on i.id=e.institution_id
   join public.atena_requests r on r.id=e.request_id
   join public.atena_pilot_operators o on o.id=e.updated_by_operator_id and o.institution_id=e.institution_id
   where e.module=p_module and ((p_profile is not null and e.profile_id=p_profile and e.visible_student)
     or (p_profile is null and e.institution_id=p_institution and e.area_id=p_area and e.request_id=p_request)));
end; $$;
revoke all on function public.atena_education_enrollments(text,text),
 public.atena_education_save(text,text,uuid,text,text,uuid,integer,jsonb,boolean),
 public.atena_education_read(text,text,text,text,uuid) from public,anon,authenticated;
grant execute on function public.atena_education_enrollments(text,text),
 public.atena_education_save(text,text,uuid,text,text,uuid,integer,jsonb,boolean),
 public.atena_education_read(text,text,text,text,uuid) to authenticated;
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
          where c in ('catalog.publish', 'requests.read', 'requests.decide', 'calendar.read', 'calendar.write', 'communications.write', 'responses.read', 'education.read', 'education.write')
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
        and a.capabilities && array['catalog.publish', 'requests.read', 'requests.decide', 'calendar.read', 'calendar.write', 'communications.write', 'responses.read', 'education.read', 'education.write']::text[]
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
