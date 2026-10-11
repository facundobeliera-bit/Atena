-- LOCAL CANDIDATE ONLY: remote application requires separate authorization.
-- No existing row, Auth identity, grant or session is changed on application.
begin;
create table atena_private.onboarding_reviewers (
 user_id uuid primary key references auth.users(id), active boolean not null default true
);
create table atena_private.institution_applications (
 id uuid primary key default gen_random_uuid(), applicant uuid not null references auth.users(id),
 operation_id uuid not null, name text not null check(length(name) between 3 and 160),
 reference text not null check(length(reference) between 4 and 160),
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 institution_id text references public.atena_pilot_institutions(id),
 reviewer uuid references auth.users(id), review_reference text,
 created_at timestamptz not null default now(), decided_at timestamptz,
 unique(applicant,operation_id), unique(applicant,reference)
);
create table atena_private.institution_registry (
 reference text primary key, institution_id text not null unique references public.atena_pilot_institutions(id)
);
create table atena_private.operator_invitations (
 id uuid primary key default gen_random_uuid(), institution_id text not null,
 area_id text not null, email text not null, capabilities text[] not null,
 issuer uuid not null references auth.users(id), expires_at timestamptz not null,
 accepted_by uuid references auth.users(id), revoked boolean not null default false,
 foreign key(institution_id,area_id) references public.atena_pilot_areas(institution_id,id)
);
create table atena_private.onboarding_audit (
 id bigint generated always as identity primary key, actor uuid not null references auth.users(id),
 action text not null, subject text not null, created_at timestamptz not null default now()
);
do $$ declare t text; begin
 foreach t in array array['onboarding_reviewers','institution_applications','institution_registry','operator_invitations','onboarding_audit'] loop
 execute format('alter table atena_private.%I enable row level security',t);
 execute format('revoke all on atena_private.%I from public,anon,authenticated,service_role',t);
 end loop;
end $$;
create function atena_private.onboarding_verified_email() returns text language plpgsql stable security definer set search_path='' as $$
declare e text; begin
 perform atena_private.require_current_session_read();
 select lower(trim(email)) into e from auth.users where id=auth.uid() and email_confirmed_at is not null;
 if e is null or e='' then raise exception 'Verified email required' using errcode='42501'; end if;
 return e;
end $$;
create function atena_private.onboarding_owner(p_institution text) returns text language plpgsql volatile security definer set search_path='' as $$
declare op text; begin
 select o.id into op from public.atena_pilot_operators o
 join public.atena_pilot_institutions i on i.id=o.institution_id
 join public.atena_pilot_identity_links l on l.institution_id=o.institution_id and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
 where o.institution_id=p_institution and o.auth_user_id=auth.uid() and o.active and o.is_owner
 and i.owner_auth_user_id=auth.uid() and l.active for share of o,i,l;
 if op is null then raise exception 'Institution owner required' using errcode='42501'; end if;
 return op;
end $$;
-- Bootstrap is an explicitly authorized administrative operation, never client self-enrolment.
create function public.atena_onboarding_reviewer(p_user uuid,p_active boolean) returns void language plpgsql security definer set search_path='' as $$
begin
 if p_active is null or not exists(select 1 from auth.users where id=p_user and email_confirmed_at is not null and deleted_at is null) then
 raise exception 'Verified reviewer required' using errcode='22023'; end if;
 insert into atena_private.onboarding_reviewers values(p_user,p_active) on conflict(user_id) do update set active=excluded.active;
 insert into atena_private.onboarding_audit(actor,action,subject) values(p_user,'trusted_reviewer_configuration',p_active::text);
end $$;
revoke all on function public.atena_onboarding_reviewer(uuid,boolean) from public,anon,authenticated;
grant execute on function public.atena_onboarding_reviewer(uuid,boolean) to service_role;
create function public.atena_onboarding_state() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare is_reviewer boolean; result jsonb; begin
 perform atena_private.require_current_session_read();
 perform atena_private.onboarding_verified_email();
 is_reviewer:=exists(select 1 from atena_private.onboarding_reviewers where user_id=auth.uid() and active);
 select jsonb_build_object('auth_user_id',auth.uid(),'reviewer',is_reviewer,
 'applications',coalesce((select jsonb_agg(to_jsonb(a)) from atena_private.institution_applications a where a.applicant=auth.uid() or (is_reviewer and a.status='pending')),'[]'::jsonb),
 'institutions',coalesce((select jsonb_agg(jsonb_build_object('id',i.id,'name',i.display_name,
 'areas',(select coalesce(jsonb_agg(to_jsonb(a)),'[]'::jsonb) from public.atena_pilot_areas a where a.institution_id=i.id),
 'operators',(select coalesce(jsonb_agg(jsonb_build_object('id',o.id,'name',o.display_name,'active',o.active,'is_owner',o.is_owner)),'[]'::jsonb) from public.atena_pilot_operators o where o.institution_id=i.id)))
 from public.atena_pilot_institutions i join public.atena_pilot_operators o on o.institution_id=i.id and o.auth_user_id=auth.uid() and o.is_owner and o.active
 join public.atena_pilot_identity_links l on l.institution_id=i.id and l.operator_id=o.id and l.auth_user_id=auth.uid() and l.active
 where i.owner_auth_user_id=auth.uid()),'[]'::jsonb),
 'invitations',coalesce((select jsonb_agg(jsonb_build_object('id',v.id,'institution_id',v.institution_id,'area_id',v.area_id,'expires_at',v.expires_at))
 from atena_private.operator_invitations v where v.email=atena_private.onboarding_verified_email() and not v.revoked and v.accepted_by is null and v.expires_at>now()),'[]'::jsonb)) into result;
 return result;
end $$;
create function public.atena_onboarding_command(p_action text,p_data jsonb) returns jsonb language plpgsql volatile security definer set search_path='' as $$
#variable_conflict use_variable
declare caller uuid:=auth.uid(); email text; a atena_private.institution_applications; v atena_private.operator_invitations;
 inst text; op text; area text; reference text; nm text; caps text[]; result jsonb; target uuid;
begin
 perform atena_private.require_current_session();
 email:=atena_private.onboarding_verified_email();
 if p_action is null or p_data is null or jsonb_typeof(p_data)<>'object' then raise exception 'Invalid command' using errcode='22023'; end if;
 if p_action='apply' then
 nm:=trim(p_data->>'name'); reference:=lower(trim(p_data->>'reference'));
 if nm is null or reference is null or nullif(p_data->>'operation_id','') is null then raise exception 'Missing application data' using errcode='22023'; end if;
 -- Serializes retries and name/reference checks, without client-supplied privileged IDs.
 perform pg_advisory_xact_lock(hashtextextended(caller::text,101));
 select * into a from atena_private.institution_applications where applicant=caller and operation_id=(p_data->>'operation_id')::uuid;
 if found then
 if a.name<>nm or a.reference<>reference then raise exception 'Conflicting retry' using errcode='PT409'; end if;
 return jsonb_build_object('auth_user_id',caller,'application_id',a.id,'status',a.status);
 end if;
 if exists(select 1 from atena_private.institution_registry where institution_registry.reference=reference)
 or exists(select 1 from public.atena_pilot_institutions where lower(trim(display_name))=lower(nm)) then
 raise exception 'Institution already exists; administrative review required' using errcode='PT409'; end if;
 insert into atena_private.institution_applications(applicant,operation_id,name,reference) values(caller,(p_data->>'operation_id')::uuid,nm,reference) returning * into a;
 result:=jsonb_build_object('application_id',a.id,'status',a.status);
 elsif p_action in ('approve','reject') then
 perform 1 from atena_private.onboarding_reviewers where user_id=caller and active for share;
 if not found then raise exception 'Administrative reviewer required' using errcode='42501'; end if;
 select * into a from atena_private.institution_applications where id=(p_data->>'application_id')::uuid for update;
 if not found then raise exception 'Unknown application' using errcode='22023'; end if;
 if a.applicant=caller then raise exception 'Self approval forbidden' using errcode='42501'; end if;
 reference:=trim(p_data->>'review_reference');
 if reference is null or length(reference) not between 8 and 160 then raise exception 'Documented representation review required' using errcode='22023'; end if;
 if a.status<>'pending' then
 if a.status=(case p_action when 'approve' then 'approved' else 'rejected' end) and a.review_reference=reference then
 return jsonb_build_object('auth_user_id',caller,'status',a.status,'institution_id',a.institution_id); end if;
 raise exception 'Application already decided' using errcode='PT409'; end if;
 if p_action='approve' then
 if coalesce((p_data->>'representation_checked')::boolean,false) is not true then raise exception 'Explicit representation review required' using errcode='22023'; end if;
 perform 1 from auth.users where id=a.applicant and email_confirmed_at is not null and deleted_at is null and (banned_until is null or banned_until<=now()) for share;
 if not found then raise exception 'Applicant not eligible' using errcode='42501'; end if;
 perform pg_advisory_xact_lock(hashtextextended(lower(a.name),102));
 if exists(select 1 from public.atena_pilot_institutions where lower(trim(display_name))=lower(a.name)) then raise exception 'Institution already exists' using errcode='PT409'; end if;
 inst:='remote-'||gen_random_uuid()::text; op:='owner-'||gen_random_uuid()::text; area:='area-'||gen_random_uuid()::text;
 insert into public.atena_pilot_institutions(id,owner_auth_user_id,display_name) values(inst,a.applicant,a.name);
 insert into atena_private.institution_registry values(a.reference,inst);
 insert into public.atena_pilot_operators(institution_id,id,auth_user_id,display_name,is_owner) values(inst,op,a.applicant,'Responsable institucional',true);
 insert into public.atena_pilot_identity_links(auth_user_id,local_account_id,institution_id,operator_id,verification_ref,verified_by)
 values(a.applicant,'pilot-remote-'||gen_random_uuid()::text,inst,op,reference,caller::text);
 insert into public.atena_pilot_areas(institution_id,id,display_name) values(inst,area,'Área inicial');
 insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities) values(inst,area,op,array['catalog.publish','requests.read','requests.decide']);
 end if;
 update atena_private.institution_applications set status=case p_action when 'approve' then 'approved' else 'rejected' end,
 institution_id=inst,reviewer=caller,review_reference=reference,decided_at=now() where id=a.id returning * into a;
 result:=jsonb_build_object('status',a.status,'institution_id',inst);
 elsif p_action in ('area_create','area_rename','invite','revoke_operator') then
 inst:=p_data->>'institution_id'; op:=atena_private.onboarding_owner(inst);
 if p_action='area_create' then
 -- A stable client operation UUID is a retry key, not a privileged identifier.
 area:='area-'||encode(sha256(convert_to(inst||':'||(p_data->>'operation_id')::uuid::text,'UTF8')),'hex');
 nm:=trim(p_data->>'name');
 if nm is null or length(nm) not between 1 and 160 then raise exception 'Invalid area name' using errcode='22023'; end if;
 insert into public.atena_pilot_areas(institution_id,id,display_name) values(inst,area,nm) on conflict(institution_id,id) do nothing;
 if not exists(select 1 from public.atena_pilot_areas where institution_id=inst and id=area and display_name=nm) then raise exception 'Conflicting retry' using errcode='PT409'; end if;
 insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities) values(inst,area,op,array['catalog.publish','requests.read','requests.decide']) on conflict do nothing;
 result:=jsonb_build_object('area_id',area);
 elsif p_action='area_rename' then
 nm:=trim(p_data->>'name');
 if nm is null or length(nm) not between 1 and 160 then raise exception 'Invalid area name' using errcode='22023'; end if;
 update public.atena_pilot_areas set display_name=nm where institution_id=inst and id=p_data->>'area_id';
 if not found then raise exception 'Unknown area' using errcode='42501'; end if;
 result:='{}'::jsonb;
 elsif p_action='invite' then
 area:=p_data->>'area_id';
 perform 1 from public.atena_pilot_areas where institution_id=inst and id=area and active for share;
 if not found then raise exception 'Unauthorized area' using errcode='42501'; end if;
 select array_agg(value) into caps from jsonb_array_elements_text(p_data->'capabilities');
 if caps is null or cardinality(caps)=0 or not caps<@array['catalog.publish','requests.read','requests.decide'] then raise exception 'Invalid capabilities' using errcode='42501'; end if;
 perform 1 from public.atena_pilot_assignments where institution_id=inst and area_id=area and operator_id=op and active and capabilities @> caps for share;
 if not found then raise exception 'Cannot delegate unavailable capabilities' using errcode='42501'; end if;
 if nullif(trim(p_data->>'email'),'') is null or p_data->>'email' not like '%@%' then raise exception 'Invalid invitation email' using errcode='22023'; end if;
 insert into atena_private.operator_invitations(institution_id,area_id,email,capabilities,issuer,expires_at)
 values(inst,area,lower(trim(p_data->>'email')),caps,caller,now()+interval '48 hours') returning * into v;
 result:=jsonb_build_object('invitation_id',v.id,'expires_at',v.expires_at);
 else
 select auth_user_id into target from public.atena_pilot_operators where institution_id=inst and id=p_data->>'operator_id' and not is_owner for update;
 if target is null or target=caller then raise exception 'Cannot revoke owner or unknown operator' using errcode='42501'; end if;
 update public.atena_pilot_identity_links set active=false,revoked_at=now() where institution_id=inst and operator_id=p_data->>'operator_id' and active;
 update public.atena_pilot_assignments set active=false where institution_id=inst and operator_id=p_data->>'operator_id';
 update public.atena_pilot_operators set active=false where institution_id=inst and id=p_data->>'operator_id';
 update atena_private.operator_invitations set revoked=true where institution_id=inst and (accepted_by=target or email=(select lower(trim(u.email)) from auth.users u where u.id=target));
 result:='{}'::jsonb;
 end if;
 elsif p_action='accept_invitation' then
 select * into v from atena_private.operator_invitations where id=(p_data->>'invitation_id')::uuid for update;
 if not found or v.revoked or v.expires_at<=now() or v.email<>email then raise exception 'Invitation unavailable' using errcode='42501'; end if;
 -- Recheck issuer authority at acceptance, not merely at creation.
 perform 1 from public.atena_pilot_operators o join public.atena_pilot_institutions i on i.id=o.institution_id
 join public.atena_pilot_identity_links l on l.institution_id=o.institution_id and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
 join public.atena_pilot_assignments s on s.institution_id=o.institution_id and s.operator_id=o.id and s.area_id=v.area_id
 join public.atena_pilot_areas ar on ar.institution_id=s.institution_id and ar.id=s.area_id
 where o.institution_id=v.institution_id and o.auth_user_id=v.issuer and o.active and o.is_owner and i.owner_auth_user_id=v.issuer and l.active and s.active and ar.active and s.capabilities @> v.capabilities for share of o,i,l,s,ar;
 if not found then raise exception 'Invitation issuer no longer authorized' using errcode='42501'; end if;
 if v.accepted_by is not null then
 if v.accepted_by<>caller then raise exception 'Invitation consumed' using errcode='42501'; end if;
 return jsonb_build_object('auth_user_id',caller,'institution_id',v.institution_id);
 end if;
 perform pg_advisory_xact_lock(hashtextextended(v.institution_id||caller::text,103));
 select id into op from public.atena_pilot_operators where institution_id=v.institution_id and auth_user_id=caller;
 if op is not null then
 perform 1 from public.atena_pilot_operators o join public.atena_pilot_identity_links l on l.institution_id=o.institution_id and l.operator_id=o.id and l.auth_user_id=o.auth_user_id
 where o.institution_id=v.institution_id and o.id=op and o.active and not o.is_owner and l.active for share of o,l;
 if not found then raise exception 'Existing operator requires administrative review' using errcode='PT409'; end if;
 else
 op:='operator-'||gen_random_uuid()::text;
 insert into public.atena_pilot_operators(institution_id,id,auth_user_id,display_name) values(v.institution_id,op,caller,'Operador invitado');
 insert into public.atena_pilot_identity_links(auth_user_id,local_account_id,institution_id,operator_id,verification_ref,verified_by)
 values(caller,'pilot-remote-'||gen_random_uuid()::text,v.institution_id,op,'invitation:'||v.id::text,v.issuer::text);
 end if;
 insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities) values(v.institution_id,v.area_id,op,v.capabilities) on conflict(institution_id,area_id,operator_id) do update set active=true,capabilities=excluded.capabilities;
 update atena_private.operator_invitations set accepted_by=caller where id=v.id;
 result:=jsonb_build_object('institution_id',v.institution_id,'operator_id',op);
 else raise exception 'Unknown command' using errcode='22023'; end if;
 insert into atena_private.onboarding_audit(actor,action,subject) values(caller,p_action,coalesce(a.id::text,v.id::text,inst,'none'));
 return result||jsonb_build_object('auth_user_id',caller);
end $$;
revoke all on function atena_private.onboarding_verified_email(),atena_private.onboarding_owner(text) from public,anon,authenticated,service_role;
revoke all on function public.atena_onboarding_state(),public.atena_onboarding_command(text,jsonb) from public,anon,authenticated;
grant execute on function public.atena_onboarding_state(),public.atena_onboarding_command(text,jsonb) to authenticated;
commit;
