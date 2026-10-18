-- LOCAL CANDIDATE ONLY. No remote application without separate authorization.
-- Depends on institutional onboarding 20261010000000 and catalog/session guards.
-- Public presentation is NOT legal identity, ownership, Auth email or a role.
begin;
create table atena_private.institution_public_profiles (
 institution_id text primary key references public.atena_pilot_institutions(id),
 revision integer not null check(revision>0), document jsonb not null,
 updated_at timestamptz not null default clock_timestamp()
);
create table atena_private.institution_profile_events (
 institution_id text not null references public.atena_pilot_institutions(id),
 operation_id uuid not null, actor uuid not null references auth.users(id),
 operator_id text not null, expected_revision integer not null,
 previous_document jsonb, document jsonb not null, result jsonb not null,
 created_at timestamptz not null default clock_timestamp(),
 primary key(institution_id,operation_id),
 foreign key(institution_id,operator_id) references public.atena_pilot_operators(institution_id,id)
);
alter table atena_private.institution_public_profiles enable row level security;
alter table atena_private.institution_profile_events enable row level security;
revoke all on atena_private.institution_public_profiles,atena_private.institution_profile_events from public,anon,authenticated,service_role;

create function public.atena_institution_profile(p_institution text) returns jsonb
language plpgsql volatile security definer set search_path='' as $$
declare p atena_private.institution_public_profiles%rowtype;
begin
 perform atena_private.require_current_session();
 perform atena_private.onboarding_verified_email();
 perform atena_private.onboarding_owner(p_institution);
 select * into p from atena_private.institution_public_profiles where institution_id=p_institution;
 return jsonb_build_object('auth_user_id',auth.uid(),'institution_id',p_institution,'revision',coalesce(p.revision,0),
 'document',coalesce(p.document,jsonb_build_object('public_name',(select display_name from public.atena_pilot_institutions where id=p_institution),
 'description','','country','','province','','city','','address','','phone','','email','','opening_hours','')));
end $$;
create function public.atena_institution_profile_save(p_institution text,p_operation uuid,p_revision integer,p_document jsonb)
returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare op text; old atena_private.institution_public_profiles%rowtype;
 event atena_private.institution_profile_events%rowtype; result jsonb; doc jsonb; k text;
begin
 perform atena_private.require_current_session();
 perform atena_private.onboarding_verified_email();
 op:=atena_private.onboarding_owner(p_institution);
 if p_operation is null or p_revision is null or p_revision<0 or p_document is null or jsonb_typeof(p_document)<>'object' then
 raise exception 'Invalid public profile' using errcode='22023';end if;
 if (select count(*) from jsonb_object_keys(p_document))<>9 or exists(select 1 from jsonb_object_keys(p_document) as fields(field_key)
 where fields.field_key not in ('public_name','description','country','province','city','address','phone','email','opening_hours')) then
 raise exception 'Unexpected profile field' using errcode='22023';end if;
 doc:='{}'::jsonb;
 for k in select jsonb_object_keys(p_document) loop
 if jsonb_typeof(p_document->k)<>'string' or length(p_document->>k)>(case when k='description' then 2000 when k='opening_hours' then 600 when k='address' then 300 else 160 end) then
 raise exception 'Invalid profile field' using errcode='22023';end if;
 doc:=doc||jsonb_build_object(k,btrim(p_document->>k));
 end loop;
 if length(doc->>'public_name')<1 or ((doc->>'email')<>'' and (doc->>'email')!~'^[^[:space:]@]+@[^[:space:]@]+[.][^[:space:]@]+$') then
 raise exception 'Invalid public name or contact email' using errcode='22023';end if;
 perform pg_advisory_xact_lock(hashtextextended('institution-public-profile:'||p_institution,19));
 select * into event from atena_private.institution_profile_events where institution_id=p_institution and operation_id=p_operation;
 if found then
 if event.actor<>auth.uid() or event.expected_revision<>p_revision or event.document<>doc then
 raise exception 'Conflicting retry' using errcode='PT409';end if;
 return event.result;
 end if;
 select * into old from atena_private.institution_public_profiles where institution_id=p_institution for update;
 if coalesce(old.revision,0)<>p_revision then raise exception 'Profile changed; reload' using errcode='PT409';end if;
 insert into atena_private.institution_public_profiles values(p_institution,p_revision+1,doc,clock_timestamp())
 on conflict(institution_id) do update set revision=excluded.revision,document=excluded.document,updated_at=excluded.updated_at;
 result:=jsonb_build_object('auth_user_id',auth.uid(),'institution_id',p_institution,'operation_id',p_operation,'revision',p_revision+1,'document',doc);
 insert into atena_private.institution_profile_events(institution_id,operation_id,actor,operator_id,expected_revision,previous_document,document,result)
 values(p_institution,p_operation,auth.uid(),op,p_revision,old.document,doc,result);
 return result;
end $$;
revoke all on function public.atena_institution_profile(text),public.atena_institution_profile_save(text,uuid,integer,jsonb) from public,anon,authenticated,service_role;
grant execute on function public.atena_institution_profile(text),public.atena_institution_profile_save(text,uuid,integer,jsonb) to authenticated;

-- Same publication visibility, pagination and live capacity. Only allowlisted
-- public presentation fields are overlaid; no private row or audit is exposed.
create or replace function public.atena_catalog_read(p_offset integer default 0,p_limit integer default 200)
returns setof public.atena_catalog_publications
language plpgsql stable security definer set search_path='' as $$
declare publication public.atena_catalog_publications%rowtype; scope atena_private.catalog_scopes%rowtype;
 groups jsonb; profile jsonb; details jsonb;
begin
 if p_offset is null or p_offset<0 or p_limit is null or p_limit not between 1 and 200 then
 raise exception 'Invalid page' using errcode='22023';end if;
 for publication in select p.* from public.atena_catalog_publications p
 where p.publication_state='published' and atena_private.catalog_visible(p.institution_id,p.area_id)
 order by p.area_id offset p_offset limit p_limit loop
 select * into strict scope from atena_private.catalog_scopes where public_area_id=publication.area_id;
 select coalesce(jsonb_agg(atena_private.catalog_live_group(item,scope.institution_id,scope.area_id) order by ord),'[]'::jsonb)
 into groups from jsonb_array_elements(publication.document->'groups') with ordinality items(item,ord);
 publication.document:=jsonb_set(publication.document,'{groups}',groups);
 select document into profile from atena_private.institution_public_profiles where institution_id=scope.institution_id;
 if found then
 details:=(publication.document->'institution')||jsonb_build_object('name',profile->>'public_name',
 'description',profile->>'description','address',profile->>'address','phone',profile->>'phone',
 'email',profile->>'email','opening_hours',profile->>'opening_hours');
 -- Empty location retains the existing published area location.
 if profile->>'country'<>'' then details:=details||jsonb_build_object('country',profile->>'country');end if;
 if profile->>'province'<>'' then details:=details||jsonb_build_object('province',profile->>'province');end if;
 if profile->>'city'<>'' then details:=details||jsonb_build_object('city',profile->>'city');end if;
 publication.document:=jsonb_set(publication.document,'{institution}',details);
 end if;
 return next publication;
 end loop;
end $$;
commit;
