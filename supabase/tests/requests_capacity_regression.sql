-- Prepared PostgreSQL regression, NOT executed against Supabase.
-- Run ONLY after applying candidates to a disposable database named below.
\set ON_ERROR_STOP on
select current_database()='atena_disposable_candidate' as safe_database \gset
\if :safe_database
\else
  \echo 'REFUSED: requires atena_disposable_candidate'
  \quit 3
\endif
begin;
insert into auth.users(id) values ('11111111-1111-4111-8111-111111111111'),('22222222-2222-4222-8222-222222222222'),('33333333-3333-4333-8333-333333333333');
insert into public.atena_pilot_institutions(id,owner_auth_user_id,display_name) values ('test-request-school','22222222-2222-4222-8222-222222222222','Fictitious school');
insert into public.atena_pilot_areas(institution_id,id,display_name) values ('test-request-school','test-request-area','Fictitious area');
insert into public.atena_pilot_operators(institution_id,id,auth_user_id,display_name,is_owner) values ('test-request-school','test-request-operator','22222222-2222-4222-8222-222222222222','Fictitious operator',true);
insert into public.atena_pilot_assignments(institution_id,area_id,operator_id,capabilities) values ('test-request-school','test-request-area','test-request-operator',array['requests.read','requests.decide']);
insert into public.atena_pilot_identity_links(auth_user_id,institution_id,operator_id,verified_by,verification_ref,local_account_id) values
 ('22222222-2222-4222-8222-222222222222','test-request-school','test-request-operator','fixture-admin','fixture-independent-check','pilot-request-owner');
insert into atena_private.catalog_namespaces values ('test-request-school','atena_'||repeat('a',64));
insert into atena_private.catalog_scopes(institution_id,area_id,public_institution_id,public_area_id) values ('test-request-school','test-request-area','atena_'||repeat('a',64),'atena_'||repeat('b',64));
insert into atena_private.applicant_links values
 ('test-profile-one','11111111-1111-4111-8111-111111111111',true,now()),('test-profile-two','11111111-1111-4111-8111-111111111111',true,now());
insert into atena_private.capacity_pools values ('test-pool','test-request-school','test-request-area','group',1,0);
insert into atena_private.request_resources values ('atena_'||repeat('c',64),'test-request-school','test-request-area','curricular','test-pool',null,true);
insert into public.atena_catalog_publications values ('atena_'||repeat('a',64),'atena_'||repeat('b',64),1,'published',
 jsonb_build_object('schema_version',2,'groups',jsonb_build_array(jsonb_build_object('id','atena_'||repeat('c',64),'kind','curricular','status','disponible'))),now());
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
do $$
declare r public.atena_requests%rowtype; retry public.atena_requests%rowtype;
begin
 r:=public.atena_request_create('test-profile-one','atena_'||repeat('c',64),'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
 retry:=public.atena_request_create('test-profile-one','atena_'||repeat('c',64),'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
 if r.id<>retry.id then raise exception 'FAIL retry'; end if;
 perform public.atena_request_create('test-profile-two','atena_'||repeat('c',64),'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
 begin
  perform public.atena_request_create('test-profile-two','atena_'||repeat('c',64),'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa');
  raise exception 'FAIL contradictory retry';
 exception when sqlstate '22023' then null; end;
 begin
  perform public.atena_request_create('test-profile-one','atena_'||repeat('c',64),'cccccccc-cccc-4ccc-8ccc-cccccccccccc');
  raise exception 'FAIL duplicate active request';
 exception when unique_violation then null; end;
 begin
  perform public.atena_request_decide(r.id,'confirmed'); raise exception 'FAIL applicant confirmation';
 exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
do $$ begin
 if exists(select 1 from public.atena_requests) then raise exception 'FAIL cross-user RLS'; end if;
 begin
  perform public.atena_request_create('test-profile-one','atena_'||repeat('c',64),'cccccccc-cccc-4ccc-8ccc-cccccccccccc');
  raise exception 'FAIL forged profile';
 exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
do $$
declare first_id uuid; second_id uuid;
begin
 select id into strict first_id from public.atena_requests where applicant_profile_id='test-profile-one';
 select id into strict second_id from public.atena_requests where applicant_profile_id='test-profile-two';
 perform public.atena_request_decide(first_id,'confirmed');
 perform public.atena_request_decide(first_id,'confirmed');
 begin
  perform public.atena_request_decide(second_id,'confirmed'); raise exception 'FAIL overflow';
 exception when sqlstate 'PT409' then null; end;
 begin
  perform public.atena_request_decide(first_id,'rejected'); raise exception 'FAIL terminal transition';
 exception when sqlstate 'PT409' then null; end;
 if (select state from public.atena_requests where id=second_id)<>'pending' then raise exception 'FAIL failed decision changed state'; end if;
end $$;
reset role;
do $$ begin
 if (select occupied from atena_private.capacity_pools where id='test-pool')<>1 then raise exception 'FAIL duplicate capacity consumption'; end if;
end $$;
-- Historical occupancy is retained even when fewer confirmations are indexed.
update atena_private.capacity_pools set occupied=2,capacity=3 where id='test-pool';
set local role authenticated;
do $$ declare pending_id uuid; begin
 select id into strict pending_id from public.atena_requests where applicant_profile_id='test-profile-two';
 perform public.atena_request_decide(pending_id,'confirmed');
 begin
  update public.atena_requests set state='pending' where id=pending_id;
  raise exception 'FAIL direct state write';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
do $$ begin
 if (select occupied from atena_private.capacity_pools where id='test-pool')<>3 then raise exception 'FAIL historical occupancy lost'; end if;
 if (select count(*) from public.atena_requests where state='confirmed')<>2 then raise exception 'FAIL unexpected confirmation'; end if;
end $$;
-- Imported overoccupancy remains evidence: no correction or clamp is performed.
update atena_private.capacity_pools set capacity=2 where id='test-pool';
insert into atena_private.applicant_links values ('test-profile-three','11111111-1111-4111-8111-111111111111',true,now());
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
do $$ begin
 begin
  perform public.atena_request_create('test-profile-three','atena_'||repeat('c',64),'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
  raise exception 'FAIL overoccupied admission';
 exception when sqlstate 'PT409' then null; end;
end $$;
reset role;
do $$ begin
 if (select occupied from atena_private.capacity_pools where id='test-pool')<>3 then raise exception 'FAIL overoccupancy hidden'; end if;
end $$;
-- Reject existing tokens after revocation, not just a new login.
update public.atena_pilot_identity_links set active=false,revoked_at=now() where institution_id='test-request-school';
set local role authenticated;
select set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
do $$ begin
 if exists(select 1 from public.atena_requests) then raise exception 'FAIL revoked institutional read'; end if;
end $$;
reset role;
rollback;
\echo 'PASS transactional cases; fixture rolled back. Two-connection races remain separately required.'
