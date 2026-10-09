-- Shared implementation of the existing confirmed-enrollment emissions flow.
-- No Auth changes, provisioning, commercial activation or historical migration.
begin;

alter table public.atena_pilot_assignments
  drop constraint atena_pilot_assignments_capabilities_requests_check;
alter table public.atena_pilot_assignments
  add constraint atena_pilot_assignments_capabilities_calendar_check check
  (capabilities <@ array['pilot.read','pilot.write','catalog.publish','requests.read',
    'requests.decide','calendar.read','calendar.write','communications.write','responses.read']::text[]);

create table atena_private.institutional_emissions (
  id uuid primary key,
  institution_id text not null,
  area_id text not null,
  group_id text,
  kind text not null check (kind in ('calendar','communication')),
  title text not null check(length(btrim(title)) between 1 and 240),
  body text not null check(length(body)<=8000),
  starts_at timestamp without time zone,
  ends_at timestamp without time zone,
  special_type text not null default 'otro' check(special_type in
    ('inicioClases','finClases','receso','inicioCiclo','finCiclo','otro')),
  rsvp_policy text not null default 'none' check(rsvp_policy in
    ('none','optional','mandatory_attendance','mandatory_ack')),
  revision integer not null check(revision>0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by_operator_id text not null,
  updated_by_operator_id text not null,
  check ((kind='calendar' and starts_at is not null) or
         (kind='communication' and starts_at is null and ends_at is null and rsvp_policy='none')),
  check(ends_at is null or ends_at>=starts_at),
  foreign key(institution_id,area_id) references public.atena_pilot_areas(institution_id,id),
  foreign key(group_id,institution_id,area_id) references atena_private.request_resources(group_id,institution_id,area_id),
  foreign key(institution_id,created_by_operator_id) references public.atena_pilot_operators(institution_id,id),
  foreign key(institution_id,updated_by_operator_id) references public.atena_pilot_operators(institution_id,id)
);
-- Recipient snapshot, matching the local calendar/inbox delivery contract.
-- Revoked Auth/profile links immediately deny reading even an older delivery.
create table atena_private.emission_recipients (
  emission_id uuid not null references atena_private.institutional_emissions(id),
  profile_id text not null references atena_private.applicant_links(profile_id),
  request_id uuid not null references public.atena_requests(id),
  rsvp text not null default 'pending' check(rsvp in ('pending','yes','no','maybe')),
  responded_at timestamptz,
  read_at timestamptz,
  hidden boolean not null default false,
  primary key(emission_id,profile_id)
);
create table atena_private.emission_operations (
  auth_user_id uuid not null references auth.users(id),
  operation_id uuid not null,
  emission_id uuid not null references atena_private.institutional_emissions(id),
  request_body jsonb not null,
  result jsonb not null,
  created_at timestamptz not null default now(),
  primary key(auth_user_id,operation_id)
);
create table atena_private.emission_revisions (
  emission_id uuid not null references atena_private.institutional_emissions(id),
  revision integer not null,
  operator_id text not null,
  auth_user_id uuid not null references auth.users(id),
  recorded_at timestamptz not null default now(),
  snapshot jsonb not null,
  primary key(emission_id,revision)
);
alter table atena_private.institutional_emissions enable row level security;
alter table atena_private.emission_recipients enable row level security;
alter table atena_private.emission_operations enable row level security;
alter table atena_private.emission_revisions enable row level security;
revoke all on atena_private.institutional_emissions,atena_private.emission_recipients,
  atena_private.emission_operations,atena_private.emission_revisions from public,anon,authenticated;
-- Tables are deliberately inaccessible directly. RPCs validate every read/write
-- and project approved fields, never returning private audit or other recipients.

create function public.atena_emission_enrollments(p_institution text,p_area text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if atena_private.request_actor(p_institution,p_area,'communications.write') is null and
     atena_private.request_actor(p_institution,p_area,'calendar.write') is null then
    raise exception 'Area not authorized' using errcode='42501';
  end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id',r.id,'profile_id',r.applicant_profile_id,
    'group_id',r.group_id,'kind',g.kind) order by r.id),'[]'::jsonb)
    from public.atena_requests r join atena_private.request_resources g on g.group_id=r.group_id
    join atena_private.applicant_links l on l.profile_id=r.applicant_profile_id
      and l.auth_user_id=r.applicant_auth_user_id and l.active
    where r.institution_id=p_institution and r.area_id=p_area and r.state='confirmed');
end; $$;

create function public.atena_emission_save(p_institution text,p_area text,p_id uuid,
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
  if matched<>cardinality(selected) then
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

create function public.atena_emissions_student(p_profile text,p_kind text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if not atena_private.request_is_applicant(p_profile) then
    raise exception 'Profile not authorized' using errcode='42501'; end if;
  if p_kind is null or p_kind not in ('calendar','communication') then
    raise exception 'Invalid kind' using errcode='22023'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object(
    'id',e.id,'institucionId',e.institution_id,'institucionNombre',i.display_name,
    'areaId',e.area_id,'grupoId',e.group_id,'title',e.title,'note',e.body,
    'date',to_char(e.starts_at,'YYYY-MM-DD'),'time',to_char(e.starts_at,'HH24:MI'),
    'endDate',to_char(e.ends_at,'YYYY-MM-DD'),'endTime',to_char(e.ends_at,'HH24:MI'),
    'type','evento_especial','source','institucion','locked',true,
    'allowStudentDelete',false,'allowStudentEdit',false,
    'cal_tipo','eventoEspecial','cal_tipoEspecial',e.special_type,
    'requiresRsvp',e.rsvp_policy<>'none','rsvpPolicy',e.rsvp_policy,'rsvpStatus',r.rsvp,
    'revision',e.revision,'createdAt',e.created_at,'read',r.read_at is not null)
    order by e.created_at desc,e.id),'[]'::jsonb)
    from atena_private.emission_recipients r
    join atena_private.institutional_emissions e on e.id=r.emission_id
    join public.atena_pilot_institutions i on i.id=e.institution_id
    where r.profile_id=p_profile and e.active and
      (e.kind=p_kind or p_kind='communication') and (p_kind='calendar' or not r.hidden));
end; $$;

create function public.atena_emissions_institution(p_institution text,p_area text,p_kind text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if atena_private.request_actor(p_institution,p_area,case p_kind
    when 'calendar' then 'calendar.write' when 'communication' then 'communications.write' end) is null then
    raise exception 'Area not authorized' using errcode='42501'; end if;
  return (select coalesce(jsonb_agg((to_jsonb(e)-'created_by_operator_id'-'updated_by_operator_id') ||
    jsonb_build_object('requests',(select jsonb_agg(r.request_id order by r.request_id)
      from atena_private.emission_recipients r where r.emission_id=e.id)) order by e.created_at desc,e.id),'[]'::jsonb)
    from atena_private.institutional_emissions e where e.institution_id=p_institution and e.area_id=p_area and e.kind=p_kind);
end; $$;

create function public.atena_emission_respond(p_profile text,p_id uuid,p_status text)
returns void language plpgsql volatile security definer set search_path='' as $$
declare e atena_private.institutional_emissions%rowtype;
begin
  if not atena_private.request_is_applicant(p_profile) then
    raise exception 'Profile not authorized' using errcode='42501'; end if;
  select m.* into e from atena_private.institutional_emissions m
    join atena_private.emission_recipients r on r.emission_id=m.id
    where m.id=p_id and m.active and r.profile_id=p_profile for share of m;
  if e.id is null or e.kind<>'calendar' or e.rsvp_policy='none' or
    p_status is null or p_status not in ('yes','no','maybe') or
    (p_status='no' and e.rsvp_policy in ('mandatory_attendance','mandatory_ack')) then
    raise exception 'Response not permitted' using errcode='42501'; end if;
  update atena_private.emission_recipients set rsvp=p_status,responded_at=now()
    where emission_id=p_id and profile_id=p_profile and rsvp<>p_status;
end; $$;

create function public.atena_emission_inbox_state(p_profile text,p_id uuid,p_read boolean,p_hidden boolean)
returns void language plpgsql volatile security definer set search_path='' as $$
begin
  if not atena_private.request_is_applicant(p_profile) or p_read is null or p_hidden is null then
    raise exception 'Profile not authorized' using errcode='42501'; end if;
  update atena_private.emission_recipients set read_at=case when p_read then coalesce(read_at,now()) else null end,
    hidden=p_hidden where emission_id=p_id and profile_id=p_profile;
  if not found then raise exception 'Delivery not authorized' using errcode='42501'; end if;
end; $$;

create function public.atena_emission_responses(p_institution text,p_area text)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  if atena_private.request_actor(p_institution,p_area,'responses.read') is null then
    raise exception 'Area not authorized' using errcode='42501'; end if;
  return (select coalesce(jsonb_agg(jsonb_build_object('id',e.id::text||':'||r.profile_id,
    'institucionId',e.institution_id,'areaId',e.area_id,'grupoId',e.group_id,'perfilId',r.profile_id,
    'eventId',e.id,'eventTitle',e.title,'eventDate',to_char(e.starts_at,'YYYY-MM-DD'),
    'status',r.rsvp,'respondedAt',r.responded_at) order by e.id,r.profile_id),'[]'::jsonb)
    from atena_private.emission_recipients r join atena_private.institutional_emissions e on e.id=r.emission_id
    where e.institution_id=p_institution and e.area_id=p_area and e.active and e.kind='calendar' and e.rsvp_policy<>'none');
end; $$;

revoke all on function public.atena_emission_enrollments(text,text),
  public.atena_emission_save(text,text,uuid,uuid,integer,text,text,text,uuid[],text,timestamp,timestamp,text,text,boolean),
  public.atena_emissions_student(text,text),public.atena_emissions_institution(text,text,text),
  public.atena_emission_respond(text,uuid,text),public.atena_emission_inbox_state(text,uuid,boolean,boolean),
  public.atena_emission_responses(text,text) from public,anon,authenticated;
grant execute on function public.atena_emission_enrollments(text,text),
  public.atena_emission_save(text,text,uuid,uuid,integer,text,text,text,uuid[],text,timestamp,timestamp,text,text,boolean),
  public.atena_emissions_student(text,text),public.atena_emissions_institution(text,text,text),
  public.atena_emission_respond(text,uuid,text),public.atena_emission_inbox_state(text,uuid,boolean,boolean),
  public.atena_emission_responses(text,text) to authenticated;

-- Discovery exposes only explicitly assigned capabilities; grants are not assignments.
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
          where c in ('catalog.publish', 'requests.read', 'requests.decide', 'calendar.read', 'calendar.write', 'communications.write', 'responses.read')
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
        and a.capabilities && array['catalog.publish', 'requests.read', 'requests.decide', 'calendar.read', 'calendar.write', 'communications.write', 'responses.read']::text[]
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
