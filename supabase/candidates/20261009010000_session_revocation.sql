-- LOCAL CANDIDATE. Remote application requires explicit approval.
-- No existing Auth session or user is modified on migration application.
begin;
grant usage on schema atena_private to service_role;
create table atena_private.session_security (
 auth_user_id uuid primary key references auth.users(id) on delete cascade,
 revoked_before timestamptz not null, disabled boolean not null default false,
 reason text not null check(reason in ('credential_change','account_disabled','administrative','self_logout'))
);
alter table atena_private.session_security enable row level security;
revoke all on atena_private.session_security from public,anon,authenticated;
create function atena_private.session_allowed()
returns boolean language plpgsql stable security definer set search_path='' as $$
declare sid text; caller uuid:=auth.uid();
begin
 if caller is null then return false; end if;
 sid:=nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'session_id';
 if sid is null or sid!~*'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then return false; end if;
 return exists(select 1 from auth.sessions s join auth.users u on u.id=s.user_id
 left join atena_private.session_security sec on sec.auth_user_id=u.id
 where s.id=sid::uuid and u.id=caller and u.deleted_at is null
 and (u.banned_until is null or u.banned_until<=now())
 and (s.not_after is null or s.not_after>now()) and not coalesce(sec.disabled,false)
 and (sec.revoked_before is null or s.created_at>sec.revoked_before));
end; $$;
-- STABLE RPCs run in READ ONLY transactions under PostgREST, even for POST.
-- Validate the statement snapshot without row locks; writes use the guard below.
create function atena_private.require_current_session_read()
returns void language plpgsql stable security definer set search_path='' as $$
begin
 if not atena_private.session_allowed() then raise exception 'Session revoked or expired' using errcode='42501'; end if;
end; $$;
revoke all on function atena_private.require_current_session_read() from public,anon,authenticated;
create function atena_private.require_current_session()
returns void language plpgsql volatile security definer set search_path='' as $$
begin
 -- Serialize RPCs against password changes, administrative cutoffs and session
 -- deletion. Revocation completes after already-authorized transactions finish.
 perform 1 from auth.users where id=auth.uid() for share;
 if not atena_private.session_allowed() then raise exception 'Session revoked or expired' using errcode='42501'; end if;
 perform 1 from auth.sessions where user_id=auth.uid()
 and id=(nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'session_id')::uuid for share;
 if not found or not atena_private.session_allowed() then raise exception 'Session revoked or expired' using errcode='42501'; end if;
end; $$;
revoke all on function atena_private.session_allowed(),atena_private.require_current_session() from public,anon,authenticated;
grant execute on function atena_private.session_allowed() to authenticated;
create function atena_private.revoke_sessions(p_user uuid,p_disable boolean,p_reason text)
returns void language plpgsql volatile security definer set search_path='' as $$
begin
 if p_user is null or p_disable is null or p_reason is null or p_reason not in ('credential_change','account_disabled','administrative','self_logout') then raise exception 'Invalid revocation' using errcode='22023'; end if;
 perform 1 from auth.users where id=p_user for update;
 if not found then raise exception 'Unknown user' using errcode='22023'; end if;
 insert into atena_private.session_security values(p_user,clock_timestamp(),p_disable,p_reason)
 on conflict(auth_user_id) do update set revoked_before=excluded.revoked_before,
 disabled=atena_private.session_security.disabled or excluded.disabled,reason=excluded.reason;
end; $$;
revoke all on function atena_private.revoke_sessions(uuid,boolean,text) from public,anon,authenticated;
grant execute on function atena_private.revoke_sessions(uuid,boolean,text) to service_role;
create function atena_private.credential_revocation_trigger()
returns trigger language plpgsql security definer set search_path='' as $$
begin
 if new.encrypted_password is distinct from old.encrypted_password then
  perform atena_private.revoke_sessions(new.id,false,'credential_change');
 elsif new.banned_until is distinct from old.banned_until or new.deleted_at is distinct from old.deleted_at then
  perform atena_private.revoke_sessions(new.id,false,'account_disabled');
 end if;
 return new;
end; $$;
revoke all on function atena_private.credential_revocation_trigger() from public,anon,authenticated;
create trigger atena_sensitive_auth_change after update of encrypted_password,banned_until,deleted_at on auth.users
 for each row execute function atena_private.credential_revocation_trigger();
-- Preserve signatures, owners, grants and business bodies. Fail closed on an
-- unexpected language or body. Public catalog remains anonymous.
do $$
declare p record; body text; definition text; guard_name text;
begin
 for p in select pr.oid,pr.proname,pr.prosrc,pr.provolatile,l.lanname from pg_proc pr
 join pg_namespace n on n.oid=pr.pronamespace join pg_language l on l.oid=pr.prolang
 where n.nspname='public' and pr.proname like 'atena_%' and pr.proname<>'atena_catalog_read'
 and has_function_privilege('authenticated',pr.oid,'EXECUTE') loop
  if p.lanname<>'plpgsql' then raise exception 'Unexpected RPC language: %',p.proname; end if;
  guard_name:=case when p.provolatile='v' then 'require_current_session' else 'require_current_session_read' end;
  body:=regexp_replace(p.prosrc,E'(^|\n)[ \t]*begin([ \t\r\n])',$guard$\1begin
 perform atena_private.$guard$ || guard_name || $guard$();\2$guard$,'i');
  if body=p.prosrc then raise exception 'RPC guard not installed: %',p.proname; end if;
  definition:=pg_get_functiondef(p.oid);
  execute replace(definition,p.prosrc,body);
 end loop;
 for p in select c.relname from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relkind='r' and c.relname like 'atena_%'
 and c.relname<>'atena_catalog_publications' and c.relrowsecurity loop
  execute format('create policy atena_live_session on public.%I as restrictive for all to authenticated using ((select atena_private.session_allowed())) with check ((select atena_private.session_allowed()))',p.relname);
 end loop;
end; $$;
create function public.atena_revoke_my_sessions()
returns void language plpgsql volatile security definer set search_path='' as $$
begin
 perform 1 from auth.users where id=auth.uid() for update;
 perform atena_private.require_current_session();
 perform atena_private.revoke_sessions(auth.uid(),false,'self_logout');
end; $$;
revoke all on function public.atena_revoke_my_sessions() from public,anon,authenticated;
grant execute on function public.atena_revoke_my_sessions() to authenticated;
do $$
declare definition text; body text;
begin
 select pg_get_functiondef(oid),prosrc into definition,body from pg_proc
 where oid='public.atena_authenticated_context()'::regprocedure;
 definition:=replace(definition,body,replace(body,
 '''auth_user_id'', caller,','''session_guard_version'', 1, ''auth_user_id'', caller,'));
 execute definition;
end; $$;
commit;
