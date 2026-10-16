-- LOCAL CANDIDATE ONLY. Explicit remote approval required.
-- Existing reviewers, profiles and ownership only; no new roles/Auth changes.
begin;
create table atena_private.identity_corrections (
 id uuid primary key default gen_random_uuid(), applicant uuid not null references auth.users(id),
 operation_id uuid not null, scope text not null check(scope in ('family','institution')),
 target_id text not null, previous_name text not null, previous_birth_date date,
 proposed_name text not null check(length(btrim(proposed_name)) between 3 and 160), proposed_birth_date date,
 reason text not null check(length(btrim(reason)) between 8 and 300),
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 reviewer uuid references auth.users(id), review_reference text, created_at timestamptz not null default now(), decided_at timestamptz,
 unique(applicant,operation_id),
 check((scope='family' and previous_birth_date is not null and proposed_birth_date is not null) or
       (scope='institution' and previous_birth_date is null and proposed_birth_date is null))
);
create unique index identity_one_pending on atena_private.identity_corrections(scope,target_id) where status='pending';
alter table atena_private.identity_corrections enable row level security;
revoke all on atena_private.identity_corrections from public,anon,authenticated,service_role;
create function public.atena_identity_correction_state() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare caller uuid:=auth.uid(); fr boolean; ir boolean;
begin
 perform atena_private.require_current_session_read();
 perform atena_private.onboarding_verified_email();
 fr:=exists(select 1 from atena_private.family_reviewers where user_id=caller and active);
 ir:=exists(select 1 from atena_private.onboarding_reviewers where user_id=caller and active);
 return jsonb_build_object('auth_user_id',caller,'family_reviewer',fr,'institution_reviewer',ir,
 'targets',(select coalesce(jsonb_agg(t),'[]') from (
  select 'family' as scope,p.id,p.name,p.birth_date from atena_private.family_profiles p
  where exists(select 1 from atena_private.authorized_applicants a where a.profile_id=p.id and a.auth_user_id=caller)
  union all
  select 'institution',i.id,i.display_name,null::date from public.atena_pilot_institutions i
  where i.owner_auth_user_id=caller and exists(select 1 from public.atena_pilot_operators o
   join public.atena_pilot_identity_links l on l.institution_id=o.institution_id and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
   where o.institution_id=i.id and o.auth_user_id=caller and o.active and o.is_owner and l.active and l.revoked_at is null)
 ) t),
 'applications',(select coalesce(jsonb_agg(a order by a.created_at),'[]') from atena_private.identity_corrections a
  where a.applicant=caller or (a.scope='family' and fr) or (a.scope='institution' and ir)));
end; $$;
create function public.atena_identity_correction_command(p_action text,p_data jsonb) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare caller uuid:=auth.uid(); c atena_private.identity_corrections%rowtype;
 scope text; target text; nm text; dob date; oldname text; olddob date; evidence text; reason text;
 opid uuid; ownerid uuid; approved boolean; affected uuid;
begin
 perform atena_private.require_current_session();
 perform atena_private.onboarding_verified_email();
 if p_data is null or jsonb_typeof(p_data)<>'object' then raise exception 'Invalid correction' using errcode='22023';end if;
 if p_action='apply' then
  if exists(select 1 from jsonb_object_keys(p_data) k where k not in ('scope','target_id','name','birth_date','reason','operation_id')) then
   raise exception 'Unsupported identity fields' using errcode='22023';end if;
  scope:=p_data->>'scope';target:=p_data->>'target_id';nm:=btrim(p_data->>'name');reason:=btrim(p_data->>'reason');
  dob:=nullif(p_data->>'birth_date','')::date;opid:=(p_data->>'operation_id')::uuid;
  if opid is null or nm is null or length(nm) not between 3 and 160 or reason is null or length(reason) not between 8 and 300 then
   raise exception 'Invalid correction fields' using errcode='22023';end if;
  -- Serialize retries without granting authority from a client-supplied target.
  perform pg_advisory_xact_lock(hashtextextended(caller::text,161));
  if scope='family' then
   perform 1 from atena_private.authorized_applicants where profile_id=target and auth_user_id=caller for share;
   if not found then raise exception 'Profile not authorized' using errcode='42501';end if;
   select name,birth_date into oldname,olddob from atena_private.family_profiles where id=target for share;
   if not found then raise exception 'Profile unavailable' using errcode='42501';end if;
   if dob is null or dob>current_date or dob<date '1900-01-01' or
    (dob<=(current_date-interval '18 years')::date)<>(olddob<=(current_date-interval '18 years')::date) then
    raise exception 'Age boundary requires separate verified transition' using errcode='22023';end if;
  elsif scope='institution' then
   perform atena_private.onboarding_owner(target);
   select display_name into oldname from public.atena_pilot_institutions where id=target for share;
   if dob is not null then raise exception 'Unsupported institution field' using errcode='22023';end if;
  else raise exception 'Unknown correction scope' using errcode='22023';end if;
  select * into c from atena_private.identity_corrections where applicant=caller and operation_id=opid;
  if found then
   if c.scope<>scope or c.target_id<>target or c.proposed_name<>nm or c.proposed_birth_date is distinct from dob or c.reason<>reason then
    raise exception 'Conflicting correction retry' using errcode='PT409';end if;
   return jsonb_build_object('auth_user_id',caller,'application_id',c.id,'status',c.status);
  end if;
  if oldname=nm and olddob is not distinct from dob then raise exception 'No identity change' using errcode='22023';end if;
  insert into atena_private.identity_corrections(applicant,operation_id,scope,target_id,previous_name,previous_birth_date,proposed_name,proposed_birth_date,reason)
  values(caller,opid,scope,target,oldname,olddob,nm,dob,reason) returning * into c;
 elsif p_action in ('approve','reject') then
  if exists(select 1 from jsonb_object_keys(p_data) k where k not in ('application_id','review_reference','identity_checked')) then
   raise exception 'Unsupported review fields' using errcode='22023';end if;
  select * into c from atena_private.identity_corrections where id=(p_data->>'application_id')::uuid;
  if not found then raise exception 'Correction unavailable' using errcode='42501';end if;
  if c.scope='family' then
   perform 1 from atena_private.family_reviewers where user_id=caller and active for share;
  else
   perform 1 from atena_private.onboarding_reviewers where user_id=caller and active for share;
  end if;
  if not found or c.applicant=caller then raise exception 'Independent authorized reviewer required' using errcode='42501';end if;
  evidence:=btrim(p_data->>'review_reference');approved:=p_action='approve';
  if evidence is null or length(evidence) not between 8 and 160 or
   (approved and coalesce((p_data->>'identity_checked')::boolean,false) is not true) then
   raise exception 'Documented identity review required' using errcode='22023';end if;
  select * into strict c from atena_private.identity_corrections where id=c.id for update;
  if c.status<>'pending' then
   if c.status=(case when approved then 'approved' else 'rejected' end) and c.reviewer=caller and c.review_reference=evidence then
    return jsonb_build_object('auth_user_id',caller,'application_id',c.id,'status',c.status);end if;
   raise exception 'Correction already decided' using errcode='PT409';end if;
  if approved then
   -- Recheck the applicant's live authorization; never restore a revoked link.
   perform 1 from auth.users where id=c.applicant and deleted_at is null and email_confirmed_at is not null
    and (banned_until is null or banned_until<=now()) for share;
   if not found or exists(select 1 from atena_private.session_security where auth_user_id=c.applicant and disabled) then
    raise exception 'Applicant disabled' using errcode='42501';end if;
   if c.scope='family' then
    perform 1 from atena_private.authorized_applicants where profile_id=c.target_id and auth_user_id=c.applicant for share;
    if not found then raise exception 'Applicant link revoked' using errcode='42501';end if;
    if exists(select 1 from atena_private.applicant_access where profile_id=c.target_id and auth_user_id=caller and active) then
     raise exception 'Reviewer linked to target' using errcode='42501';end if;
    select name,birth_date,self_user into oldname,olddob,affected from atena_private.family_profiles where id=c.target_id for update;
    if not found or affected=caller then raise exception 'Independent review required' using errcode='42501';end if;
    if c.proposed_birth_date>current_date or
     (c.proposed_birth_date<=(current_date-interval '18 years')::date)<>(olddob<=(current_date-interval '18 years')::date) then
     raise exception 'Age boundary requires separate transition' using errcode='22023';end if;
   else
    select display_name,owner_auth_user_id into oldname,ownerid from public.atena_pilot_institutions where id=c.target_id for update;
    if not found or ownerid<>c.applicant or ownerid=caller then raise exception 'Institution ownership changed' using errcode='42501';end if;
    perform 1 from public.atena_pilot_operators o join public.atena_pilot_identity_links l
     on l.institution_id=o.institution_id and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
     where o.institution_id=c.target_id and o.auth_user_id=c.applicant and o.active and o.is_owner and l.active and l.revoked_at is null for share of o,l;
    if not found then raise exception 'Owner link revoked' using errcode='42501';end if;
    perform pg_advisory_xact_lock(hashtextextended(lower(c.proposed_name),102));
    if exists(select 1 from public.atena_pilot_institutions where id<>c.target_id and lower(btrim(display_name))=lower(c.proposed_name)) then
     raise exception 'Institution name already registered' using errcode='PT409';end if;
   end if;
   if oldname<>c.previous_name or olddob is distinct from c.previous_birth_date then raise exception 'Identity changed since request' using errcode='PT409';end if;
   if c.scope='family' then
    update atena_private.family_profiles set name=c.proposed_name,birth_date=c.proposed_birth_date where id=c.target_id;
   else
    update public.atena_pilot_institutions set display_name=c.proposed_name where id=c.target_id;
   end if;
  end if;
  update atena_private.identity_corrections set status=case when approved then 'approved' else 'rejected' end,
   reviewer=caller,review_reference=evidence,decided_at=clock_timestamp() where id=c.id returning * into c;
 else raise exception 'Unsupported correction action' using errcode='22023';end if;
 -- The correction row retains old/new values, applicant, reviewer and timestamps.
 -- Ordinary clients cannot edit/delete it; profile/Auth IDs and links never change.
 return jsonb_build_object('auth_user_id',caller,'application_id',c.id,'status',c.status);
end; $$;
revoke all on function public.atena_identity_correction_state(),public.atena_identity_correction_command(text,jsonb) from public,anon,authenticated,service_role;
grant execute on function public.atena_identity_correction_state(),public.atena_identity_correction_command(text,jsonb) to authenticated;
-- Catalog drafts/publications retain history. On next explicit edit/publication,
-- use the reviewed institutional name instead of a stale client-provided label.
do $$ declare definition text; begin
 definition:=pg_get_functiondef('public.atena_catalog_workspace(text,text)'::regprocedure);
 if position('doc:=coalesce(' in definition)=0 or position('return jsonb_build_object' in definition)=0 then raise exception 'Unexpected workspace definition';end if;
 definition:=replace(definition,'return jsonb_build_object',E'doc:=jsonb_set(doc,\'{institution,name}\',to_jsonb((select display_name from public.atena_pilot_institutions where id=p_institution)));\n return jsonb_build_object');
 execute definition;
 definition:=pg_get_functiondef('public.atena_catalog_edit(text,text,uuid,integer,bigint,text,jsonb)'::regprocedure);
 if position('doc:=p_document;' in definition)=0 then raise exception 'Unexpected catalog edit definition';end if;
 execute replace(definition,'doc:=p_document;',E'doc:=jsonb_set(p_document,\'{institution,name}\',to_jsonb((select display_name from public.atena_pilot_institutions where id=p_institution)));');
end $$;
commit;
