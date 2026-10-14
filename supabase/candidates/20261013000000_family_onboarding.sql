-- LOCAL CANDIDATE ONLY. Requires 20261010000000. No remote activation authorized.
-- No legacy identity inference. Email/DNI/name never grant access to a profile.
begin;
-- Institutional reviewers do not automatically gain access to family data.
create table atena_private.family_reviewers (
 user_id uuid primary key references auth.users(id), active boolean not null
);
alter table atena_private.family_reviewers enable row level security;
revoke all on atena_private.family_reviewers from public,anon,authenticated,service_role;
create table atena_private.family_profiles (
 id text primary key references atena_private.applicant_links(profile_id),
 name text not null check(length(btrim(name)) between 1 and 160),
 birth_date date not null,
 self_user uuid unique references auth.users(id),
 created_at timestamptz not null default now()
);
create table atena_private.family_applications (
 id uuid primary key default gen_random_uuid(), applicant uuid not null references auth.users(id),
 operation_id uuid not null, kind text not null check(kind in ('adult','minor','link','self_link')),
 name text not null, birth_date date, target_profile text,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 profile_id text references atena_private.family_profiles(id),
 reviewer uuid references auth.users(id), review_reference text,
 created_at timestamptz not null default now(), reviewed_at timestamptz,
 unique(applicant,operation_id)
);
create unique index family_pending_duplicate on atena_private.family_applications
 (applicant,kind,lower(btrim(name)),coalesce(birth_date,'0001-01-01'::date),coalesce(target_profile,'')) where status='pending';
create unique index family_created_profile_duplicate on atena_private.family_applications
 (applicant,kind,lower(btrim(name)),birth_date) where kind in ('adult','minor') and status in ('pending','approved');
create table atena_private.applicant_access (
 profile_id text not null references atena_private.applicant_links(profile_id),
 auth_user_id uuid not null references auth.users(id), active boolean not null,
 verified_at timestamptz not null, primary key(profile_id,auth_user_id)
);
insert into atena_private.applicant_access select profile_id,auth_user_id,active,verified_at from atena_private.applicant_links;
create table atena_private.family_audit (
 id bigint generated always as identity primary key, actor uuid references auth.users(id),
 action text not null, subject text not null, recorded_at timestamptz not null default now(),
 check(actor is not null or action='reviewer_designated_by_service')
);
alter table atena_private.family_profiles enable row level security;
alter table atena_private.family_applications enable row level security;
alter table atena_private.applicant_access enable row level security;
alter table atena_private.family_audit enable row level security;
revoke all on atena_private.family_profiles,atena_private.family_applications,atena_private.applicant_access,atena_private.family_audit from public,anon,authenticated,service_role;

-- Keep the legacy anchor and its FKs intact. Changes to a legacy link still revoke
-- exactly that user. Newly reviewed delegates never overwrite the anchor owner.
create function atena_private.family_mirror_legacy() returns trigger
language plpgsql security definer set search_path='' as $$
begin
 if tg_op='UPDATE' and old.auth_user_id<>new.auth_user_id then
   update atena_private.applicant_access set active=false where profile_id=old.profile_id and auth_user_id=old.auth_user_id;
 end if;
 insert into atena_private.applicant_access values(new.profile_id,new.auth_user_id,new.active,new.verified_at)
 on conflict(profile_id,auth_user_id) do update set active=excluded.active,verified_at=excluded.verified_at;
 return new;
end; $$;
revoke all on function atena_private.family_mirror_legacy() from public,anon,authenticated,service_role;
create trigger family_mirror_legacy after insert or update on atena_private.applicant_links
 for each row execute function atena_private.family_mirror_legacy();

create function atena_private.family_adult(p_user uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from atena_private.family_profiles p join atena_private.applicant_access a
 on a.profile_id=p.id and a.auth_user_id=p_user and a.active
 where p.self_user=p_user and p.birth_date<=(current_date-interval '18 years')::date);
$$;
create function atena_private.family_eligible(p_profile text,p_user uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select not exists(select 1 from atena_private.family_profiles where id=p_profile) or exists(
 select 1 from atena_private.family_profiles p where p.id=p_profile and
 ((p.self_user=p_user and p.birth_date<=(current_date-interval '18 years')::date) or
 (p.self_user is null and p.birth_date>(current_date-interval '18 years')::date and atena_private.family_adult(p_user))));
$$;
revoke all on function atena_private.family_adult(uuid),atena_private.family_eligible(text,uuid) from public,anon,authenticated,service_role;
-- A simple, lockable view: existing FOR SHARE authorization locks still work.
create view atena_private.authorized_applicants as select a.* from atena_private.applicant_access a
 where a.active and atena_private.family_eligible(a.profile_id,a.auth_user_id);
revoke all on atena_private.authorized_applicants from public,anon,authenticated,service_role;
create function atena_private.family_profile_active(p_profile text) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from atena_private.authorized_applicants where profile_id=p_profile);
$$;
revoke all on function atena_private.family_profile_active(text) from public,anon,authenticated,service_role;

-- Existing request actor remains immutable audit data. The FK now supports more
-- than one separately reviewed responsible adult without duplicating the child.
do $$ declare c record; begin
 for c in select conname from pg_constraint where conrelid='public.atena_requests'::regclass
 and confrelid='atena_private.applicant_links'::regclass loop
 execute format('alter table public.atena_requests drop constraint %I',c.conname);
 end loop;
end $$;
alter table public.atena_requests add constraint atena_requests_verified_applicant_fk
 foreign key(applicant_profile_id,applicant_auth_user_id) references atena_private.applicant_access(profile_id,auth_user_id);

-- Preserve each installed RPC's session guards, capacity locks and projection.
-- Change only its authorization source. Abort on an unexpected writer.
do $$ declare f record; definition text; begin
 for f in select p.oid,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname in ('public','atena_private') and p.prokind='f'
 and p.proname not like 'family_%' and position('atena_private.applicant_links' in p.prosrc)>0 loop
 definition:=pg_get_functiondef(f.oid);
 if definition ~* '(insert into|update|delete from)\s+atena_private.applicant_links' then
   raise exception 'Unexpected applicant link writer: %',f.proname;
 end if;
 definition:=replace(definition,'atena_private.applicant_links','atena_private.authorized_applicants');
 -- Confirmed records belong to the profile, not exclusively to their submitter.
 -- A revoked submitter must not hide the child's history from another guardian.
 if position('join atena_private.authorized_applicants l' in definition)>0 then
   definition:=replace(definition,'join atena_private.authorized_applicants l','join atena_private.applicant_links l');
   definition:=replace(definition,'and l.auth_user_id=r.applicant_auth_user_id and l.active','and atena_private.family_profile_active(l.profile_id)');
 end if;
 definition:=replace(definition,'and auth_user_id=enrollment.applicant_auth_user_id and active','and active');
 definition:=replace(definition,'and l.auth_user_id=r.applicant_auth_user_id and l.active','and atena_private.family_profile_active(l.profile_id)');
 execute definition;
 end loop;
end $$;
drop policy atena_requests_authorized_read on public.atena_requests;
create policy atena_requests_authorized_read on public.atena_requests for select to authenticated using (
 atena_private.request_is_applicant(applicant_profile_id) or atena_private.request_actor(institution_id,area_id,'requests.read') is not null
);
-- The restrictive live-session policy is retained.

create function public.atena_family_reviewer(p_user uuid,p_active boolean) returns void
language plpgsql security definer set search_path='' as $$
begin
 if p_active is null or not exists(select 1 from auth.users where id=p_user
   and email_confirmed_at is not null and deleted_at is null and (banned_until is null or banned_until<=now())) then
   raise exception 'Verified reviewer required' using errcode='42501';end if;
 insert into atena_private.family_reviewers values(p_user,p_active)
 on conflict(user_id) do update set active=excluded.active;
 insert into atena_private.family_audit(actor,action,subject) values(null,'reviewer_designated_by_service',p_user::text||':'||p_active::text);
end; $$;
revoke all on function public.atena_family_reviewer(uuid,boolean) from public,anon,authenticated;
grant execute on function public.atena_family_reviewer(uuid,boolean) to service_role;

create function public.atena_family_state() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare caller uuid:=auth.uid(); review boolean;
begin
 perform atena_private.require_current_session_read();
 perform atena_private.onboarding_verified_email();
 select exists(select 1 from atena_private.family_reviewers where user_id=caller and active) into review;
 return jsonb_build_object('auth_user_id',caller,'reviewer',review,'adult',atena_private.family_adult(caller),
 'applications',(select coalesce(jsonb_agg(to_jsonb(a) order by a.created_at),'[]') from atena_private.family_applications a
 where a.applicant=caller or review),
 'profiles',(select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'name',p.name,'birth_date',p.birth_date,
 'self_user',p.self_user,'user_id',a.auth_user_id,'active',a.active) order by p.id,a.auth_user_id),'[]')
 from atena_private.family_profiles p join atena_private.applicant_access a on a.profile_id=p.id
 where review or (a.auth_user_id=caller and a.active and atena_private.family_eligible(p.id,caller))));
end; $$;

create function public.atena_family_command(p_action text,p_data jsonb) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare caller uuid:=auth.uid(); a atena_private.family_applications%rowtype; p atena_private.family_profiles%rowtype;
 op uuid; k text; nm text; dob date; target text; evidence text; pid text; affected_user uuid;
begin
 perform atena_private.require_current_session();
 perform atena_private.onboarding_verified_email();
 if p_action='apply' then
   op:=(p_data->>'operation_id')::uuid;k:=p_data->>'kind';nm:=btrim(coalesce(p_data->>'name',''));
   dob:=nullif(p_data->>'birth_date','')::date;target:=nullif(btrim(p_data->>'target_profile'),'');
   if op is null or k is null or k not in ('adult','minor','link','self_link') or length(nm)>160
     or (k in ('adult','minor') and (length(nm)<1 or dob is null or not isfinite(dob) or dob>current_date or dob<current_date-interval '120 years'))
     or (k in ('link','self_link') and (target is null or length(target)>160 or dob is not null or nm<>''))
     or (k in ('adult','minor') and target is not null) then raise exception 'Invalid application' using errcode='22023';end if;
   if k='adult' and dob>(current_date-interval '18 years')::date then raise exception 'Adult required' using errcode='42501';end if;
   if k='minor' and dob<=(current_date-interval '18 years')::date then raise exception 'Minor required' using errcode='22023';end if;
   if k in ('minor','link') and not atena_private.family_adult(caller) then raise exception 'Reviewed adult required' using errcode='42501';end if;
   perform pg_advisory_xact_lock(hashtextextended(caller::text||op::text,13));
   select * into a from atena_private.family_applications where applicant=caller and operation_id=op;
   if found then
     if a.kind<>k or a.name<>nm or a.birth_date is distinct from dob or a.target_profile is distinct from target then
       raise exception 'Operation conflict' using errcode='PT409';end if;
   else
     if k='adult' and exists(select 1 from atena_private.family_profiles where self_user=caller) then
       raise exception 'Adult already reviewed' using errcode='PT409';end if;
     -- Deliberately do not look up target here: pending links disclose nothing.
     insert into atena_private.family_applications(applicant,operation_id,kind,name,birth_date,target_profile)
       values(caller,op,k,nm,dob,target) returning * into a;
   end if;
 elsif p_action in ('approve','reject','revoke') then
   perform 1 from atena_private.family_reviewers where user_id=caller and active for share;
   if not found then raise exception 'Reviewer required' using errcode='42501';end if;
   evidence:=btrim(coalesce(p_data->>'review_reference',''));
   if length(evidence) not between 8 and 160 then raise exception 'Review reference required' using errcode='22023';end if;
   if p_action='revoke' then
     pid:=p_data->>'profile_id';affected_user:=(p_data->>'user_id')::uuid;
     if affected_user=caller then raise exception 'Independent reviewer required' using errcode='42501';end if;
     -- Serializes against all existing mutating RPCs' current-session SHARE lock.
     perform 1 from auth.users where id=affected_user for update;
     update atena_private.applicant_access set active=false where profile_id=pid and auth_user_id=affected_user
       and exists(select 1 from atena_private.family_profiles where id=pid);
     if not found then raise exception 'Reviewed link unavailable' using errcode='42501';end if;
     if exists(select 1 from atena_private.family_profiles where id=pid and self_user=affected_user) then
       update atena_private.applicant_access set active=false where auth_user_id=affected_user
         and profile_id in (select id from atena_private.family_profiles);
     end if;
     insert into atena_private.family_audit(actor,action,subject) values(caller,'revoke',pid||':'||affected_user::text||':'||evidence);
     return jsonb_build_object('auth_user_id',caller,'status','revoked');
   end if;
   select * into a from atena_private.family_applications where id=(p_data->>'application_id')::uuid for update;
   if not found or a.applicant=caller then raise exception 'Independent review required' using errcode='42501';end if;
   if a.status<>'pending' then
     if a.status=(case p_action when 'approve' then 'approved' else 'rejected' end) then
       return jsonb_build_object('auth_user_id',caller,'application_id',a.id,'profile_id',a.profile_id,'status',a.status);
     end if;
     raise exception 'Terminal application' using errcode='PT409';
   end if;
   if p_action='approve' then
     if coalesce((p_data->>'identity_checked')::boolean,false)=false or
        (a.kind in ('minor','link') and coalesce((p_data->>'responsibility_checked')::boolean,false)=false) then
       raise exception 'Explicit evidence review required' using errcode='22023';end if;
     perform 1 from auth.users where id=a.applicant and email_confirmed_at is not null and deleted_at is null
       and (banned_until is null or banned_until<=now()) for update;
     if not found then raise exception 'Applicant unavailable' using errcode='42501';end if;
     if a.kind in ('minor','link') and not atena_private.family_adult(a.applicant) then raise exception 'Reviewed adult required' using errcode='42501';end if;
     if a.kind in ('link','self_link') then
       select * into p from atena_private.family_profiles where id=a.target_profile for update;
       if not found or p.self_user is not null then raise exception 'Profile unavailable' using errcode='42501';end if;
       if (a.kind='link' and p.birth_date<=(current_date-interval '18 years')::date) or
          (a.kind='self_link' and p.birth_date>(current_date-interval '18 years')::date) then
         raise exception 'Age inconsistent' using errcode='42501';end if;
       pid:=p.id;
       if a.kind='self_link' then
         if exists(select 1 from atena_private.family_profiles where self_user=a.applicant) then
           raise exception 'Own profile already exists' using errcode='PT409';end if;
         update atena_private.family_profiles set self_user=a.applicant where id=pid;
         update atena_private.applicant_access set active=false where profile_id=pid;
       end if;
     else
       if (a.kind='adult' and a.birth_date>(current_date-interval '18 years')::date) or
          (a.kind='minor' and a.birth_date<=(current_date-interval '18 years')::date) then
         raise exception 'Age changed; review again' using errcode='PT409';end if;
       pid:='family_'||gen_random_uuid()::text;
       insert into atena_private.applicant_links values(pid,a.applicant,true,now());
       insert into atena_private.family_profiles(id,name,birth_date,self_user)
         values(pid,a.name,a.birth_date,case when a.kind='adult' then a.applicant end);
     end if;
     insert into atena_private.applicant_access values(pid,a.applicant,true,now())
       on conflict(profile_id,auth_user_id) do update set active=true,verified_at=excluded.verified_at;
   end if;
   update atena_private.family_applications set status=case p_action when 'approve' then 'approved' else 'rejected' end,
     profile_id=pid,reviewer=caller,review_reference=evidence,reviewed_at=now() where id=a.id returning * into a;
 else raise exception 'Unknown action' using errcode='22023';end if;
 insert into atena_private.family_audit(actor,action,subject) values(caller,p_action,a.id::text);
 return jsonb_build_object('auth_user_id',caller,'application_id',a.id,'profile_id',a.profile_id,'status',a.status);
end; $$;
revoke all on function public.atena_family_state(),public.atena_family_command(text,jsonb) from public,anon,authenticated,service_role;
grant execute on function public.atena_family_state(),public.atena_family_command(text,jsonb) to authenticated;
commit;
