-- LOCAL CANDIDATE. No purge policy or scheduler is enabled by this migration.
-- Existing storage is private PostgreSQL bytea, not Supabase Storage objects.
begin;
create table atena_private.document_retention_policy (
 kind text primary key check(kind in ('dni','partidaNacimiento','constanciaCuil','certificadoDomicilio','libretaSanitaria','boletin','otro')),
 enabled boolean not null default false,
 retention_days integer check(retention_days between 1 and 36500),
 applies_from timestamptz not null default clock_timestamp(),
 -- Educational/general-purpose attachments need an explicit future policy design.
 check(not enabled or (retention_days is not null and kind not in ('boletin','otro')))
);
insert into atena_private.document_retention_policy(kind)
 select unnest(array['dni','partidaNacimiento','constanciaCuil','certificadoDomicilio','libretaSanitaria','boletin','otro']);
create table atena_private.document_purge_control (
 singleton boolean primary key default true check(singleton), enabled boolean not null default false
);
insert into atena_private.document_purge_control values(true,false);
alter table atena_private.document_files add column legal_hold boolean not null default false;
create table atena_private.document_purge_audit (
 document_id uuid primary key references atena_private.document_requests(id),
 purged_at timestamptz not null default clock_timestamp(),
 bytes_removed integer not null check(bytes_removed>0),
 retention_days integer not null,
 reason text not null default 'approved_retention' check(reason='approved_retention')
);
alter table atena_private.document_retention_policy enable row level security;
alter table atena_private.document_purge_control enable row level security;
alter table atena_private.document_purge_audit enable row level security;
revoke all on atena_private.document_retention_policy,atena_private.document_purge_control,atena_private.document_purge_audit from public,anon,authenticated;
create function atena_private.document_purge_candidates()
returns table(document_id uuid,bytes_to_remove integer,retention_days integer)
language sql stable security definer set search_path='' as $$
 select f.id,octet_length(f.content),p.retention_days
 from atena_private.document_files f
 join atena_private.document_requests d on d.id=f.id
 join atena_private.document_retention_policy p on p.kind=d.kind
 where p.enabled and p.retention_days is not null and d.kind not in ('boletin','otro')
 and not f.deleted and not f.legal_hold and f.content is not null
 and f.uploaded_at>=p.applies_from and f.expires_at<=now()
 and f.uploaded_at+make_interval(days=>p.retention_days)<=now();
$$;
create function atena_private.purge_expired_documents(p_limit integer default 20)
returns integer language plpgsql volatile security definer set search_path='' as $$
declare f record; n integer:=0; permitted boolean;
begin
 if p_limit is null or p_limit<1 or p_limit>100 then raise exception 'Invalid bounded batch' using errcode='22023'; end if;
 select enabled into permitted from atena_private.document_purge_control where singleton for share;
 if permitted is not true then return 0; end if;
 -- A policy cannot be changed while this batch is applying it.
 perform 1 from atena_private.document_retention_policy order by kind for share;
 for f in select files.id,octet_length(files.content) as bytes,p.retention_days
  from atena_private.document_files files
  join atena_private.document_requests d on d.id=files.id
  join atena_private.document_retention_policy p on p.kind=d.kind
  where p.enabled and p.retention_days is not null and d.kind not in ('boletin','otro')
  and not files.deleted and not files.legal_hold and files.content is not null
  and files.uploaded_at>=p.applies_from and files.expires_at<=now()
  and files.uploaded_at+make_interval(days=>p.retention_days)<=now()
  order by files.expires_at,files.id limit p_limit for update of files skip locked
 loop
  -- One file id belongs to exactly one document request; no shared object key.
  -- Active bytes and minimal audit commit atomically, including retry on failure.
  update atena_private.document_files set content=null,deleted=true where id=f.id;
  insert into atena_private.document_purge_audit(document_id,bytes_removed,retention_days)
   values(f.id,f.bytes,f.retention_days);
  n:=n+1;
 end loop;
 return n;
end; $$;
create function atena_private.configure_document_purge_schedule(p_enable boolean)
returns void language plpgsql volatile security definer set search_path='' as $$
declare job bigint;
begin
 if p_enable is null then raise exception 'Explicit schedule action required' using errcode='22023'; end if;
 if not exists(select 1 from pg_extension where extname='pg_cron') then
  raise exception 'pg_cron is not installed; administrative authorization required' using errcode='55000';
 end if;
 if p_enable and not exists(select 1 from atena_private.document_purge_control where singleton and enabled) then
  raise exception 'Purge policy is not enabled' using errcode='55000'; end if;
 if p_enable then
  execute 'select cron.schedule($1,$2,$3)' into job
   using 'atena-private-document-purge','17 * * * *','select atena_private.purge_expired_documents(20)';
 else
  for job in execute 'select jobid from cron.job where jobname=$1' using 'atena-private-document-purge' loop
   execute 'select cron.unschedule($1)' using job;
  end loop;
 end if;
end; $$;
revoke all on function atena_private.document_purge_candidates(),atena_private.purge_expired_documents(integer),atena_private.configure_document_purge_schedule(boolean) from public,anon,authenticated;
grant execute on function atena_private.document_purge_candidates(),atena_private.purge_expired_documents(integer),atena_private.configure_document_purge_schedule(boolean) to service_role;
commit;
