-- LOCAL CANDIDATE ONLY. Not authorized for remote application.
-- No documents are seeded, no users/permissions of reviewers are changed.
-- Receipts concern ONLY auth.uid(); they do not grant representation or access.
begin;
create table atena_private.legal_receipt_control (
 singleton boolean primary key default true check(singleton),
 enabled boolean not null default false
);
insert into atena_private.legal_receipt_control values(true,false);
create table atena_private.legal_documents (
 id uuid primary key default gen_random_uuid(),
 document_key text not null check(document_key ~ '^[a-z][a-z0-9_]{2,63}$'),
 version text not null check(length(version) between 1 and 40),
 revision integer not null check(revision > 0),
 kind text not null check(kind in ('contract_acceptance','information_acknowledgement','specific_consent')),
 audience text not null check(audience in ('all','institution','family')),
 purpose text not null check(length(btrim(purpose)) between 3 and 120),
 body text not null check(length(btrim(body)) between 1 and 200000),
 content_sha256 text not null check(content_sha256 ~ '^[a-f0-9]{64}$'),
 valid_from timestamptz not null,
 valid_until timestamptz check(valid_until > valid_from),
 approved boolean not null default false,
 created_at timestamptz not null default clock_timestamp(),
 unique(document_key,version), unique(document_key,revision)
);
create table atena_private.legal_receipts (
 id uuid primary key default gen_random_uuid(),
 actor uuid not null references auth.users(id),
 document_id uuid not null references atena_private.legal_documents(id),
 operation_id uuid not null,
 action text not null check(action in ('accept','withdraw')),
 content_sha256 text not null,
 recorded_at timestamptz not null default clock_timestamp(),
 unique(actor,operation_id)
);
alter table atena_private.legal_receipt_control enable row level security;
alter table atena_private.legal_documents enable row level security;
alter table atena_private.legal_receipts enable row level security;
revoke all on atena_private.legal_receipt_control,atena_private.legal_documents,atena_private.legal_receipts from public,anon,authenticated,service_role;
-- Administrative document publishing only; no ordinary user receives this grant.
grant select,insert,update on atena_private.legal_documents to service_role;
grant select on atena_private.legal_receipts to service_role;
-- Activation remains an explicit DBA operation; no RPC enables enforcement.
create function atena_private.legal_immutable() returns trigger
language plpgsql set search_path='' as $$
begin
 if tg_table_name='legal_documents' and tg_op='INSERT' then
  new.content_sha256:=encode(sha256(convert_to(new.body,'UTF8')),'hex');
  return new;
 end if;
 if tg_table_name='legal_receipts' or tg_op='DELETE' then
  raise exception 'Legal history is immutable' using errcode='42501';
 end if;
 if (to_jsonb(new)-'approved'-'valid_until') is distinct from
    (to_jsonb(old)-'approved'-'valid_until') then
  raise exception 'Create a new legal version' using errcode='42501';
 end if;
 return new;
end; $$;
revoke all on function atena_private.legal_immutable() from public,anon,authenticated,service_role;
create trigger legal_document_immutable before insert or update or delete on atena_private.legal_documents
for each row execute function atena_private.legal_immutable();
create trigger legal_receipt_immutable before update or delete on atena_private.legal_receipts
for each row execute function atena_private.legal_immutable();

create function public.atena_legal_state() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare caller uuid:=auth.uid();
begin
 perform atena_private.require_current_session_read();
 return jsonb_build_object('enabled',(select enabled from atena_private.legal_receipt_control where singleton),
  'actor',caller,
  'documents',(select coalesce(jsonb_agg(to_jsonb(d)),'[]'::jsonb) from atena_private.legal_documents d
   where d.approved and d.valid_from<=now() and (d.valid_until is null or d.valid_until>now())
   and not exists(select 1 from atena_private.legal_documents n where n.document_key=d.document_key
    and n.revision>d.revision and n.approved and n.valid_from<=now()
    and (n.valid_until is null or n.valid_until>now()))),
  'receipts',(select coalesce(jsonb_agg(to_jsonb(r) order by r.recorded_at,r.id),'[]'::jsonb)
   from atena_private.legal_receipts r where r.actor=caller));
end; $$;

create function public.atena_legal_record(p_document uuid,p_hash text,p_action text,p_operation uuid,p_explicit boolean)
returns jsonb language plpgsql volatile security definer set search_path='' as $$
declare caller uuid:=auth.uid();d atena_private.legal_documents%rowtype;r atena_private.legal_receipts%rowtype;
begin
 perform atena_private.require_current_session();
 perform atena_private.onboarding_verified_email();
 if not exists(select 1 from atena_private.legal_receipt_control where singleton and enabled) then
  raise exception 'Legal receipts not activated' using errcode='55000';
 end if;
 if p_explicit is distinct from true or p_operation is null or p_action is null or p_action not in ('accept','withdraw') then
  raise exception 'Explicit action required' using errcode='22023';
 end if;
 perform pg_advisory_xact_lock(hashtextextended(caller::text,270));
 select * into r from atena_private.legal_receipts where actor=caller and operation_id=p_operation;
 if found then
  if r.document_id is distinct from p_document or r.content_sha256 is distinct from p_hash or r.action is distinct from p_action then
   raise exception 'Operation conflict' using errcode='23505';
  end if;
  return to_jsonb(r);
 end if;
 select * into d from atena_private.legal_documents where id=p_document for share;
 if not found or p_hash is distinct from d.content_sha256 then
  raise exception 'Unknown legal version' using errcode='22023';
 end if;
 if p_action='accept' then
  if not d.approved or d.valid_from>now() or (d.valid_until is not null and d.valid_until<=now())
   or exists(select 1 from atena_private.legal_documents n where n.document_key=d.document_key
    and n.revision>d.revision and n.approved and n.valid_from<=now()
    and (n.valid_until is null or n.valid_until>now())) then
   raise exception 'Legal version not current' using errcode='22023';
  end if;
 elsif d.kind<>'specific_consent' or not exists(select 1 from atena_private.legal_receipts
  where actor=caller and document_id=d.id and action='accept') then
  raise exception 'No personal consent to withdraw' using errcode='42501';
 end if;
 insert into atena_private.legal_receipts(actor,document_id,operation_id,action,content_sha256)
 values(caller,d.id,p_operation,p_action,d.content_sha256) returning * into r;
 return to_jsonb(r);
end; $$;
revoke all on function public.atena_legal_state(),public.atena_legal_record(uuid,text,text,uuid,boolean) from public,anon,authenticated,service_role;
grant execute on function public.atena_legal_state(),public.atena_legal_record(uuid,text,text,uuid,boolean) to authenticated;
commit;
